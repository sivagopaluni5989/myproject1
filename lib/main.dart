import "dart:io";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";
import "package:gal/gal.dart";
import "package:video_thumbnail/video_thumbnail.dart";
import "package:path_provider/path_provider.dart";
import "package:google_mobile_ads/google_mobile_ads.dart";
import "package:saf_stream/saf_stream.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:device_info_plus/device_info_plus.dart";

void main() async {
  // 🟢 Necessary initialization bindings for AdMob and background plugins
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Status Downloader",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const StatusScreen(),
    );
  }
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});
  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _safStream = SafStream();
  List<SafFileInfo> _statusFiles = [];
  bool _loading = false;

  // 🟢 Monetization Ad Systems (Using Official Google Test Unit IDs)
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _checkPermissionsAndFetch();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  // 🟢 Loads Baseline Banner Ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ⚠️ Replace with your live AdMob Banner ID later
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("AdMob Banner failed to load: \$error");
        },
      ),
    )..load();
  }

  // 🟢 Pre-loads Interstitial (Full Screen) Ad in memory
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // ⚠️ Replace with your live AdMob Interstitial ID later
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => debugPrint("AdMob Interstitial failed: \$error"),
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _loadInterstitialAd(); // Pre-load the next ad instantly for future actions
    }
  }

  // 🟢 Google Play Compliant Scoped Storage Engine Handshake
  Future<void> _checkPermissionsAndFetch() async {
    setState(() => _loading = true);
    
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      // Android 11+ require Google Scoped Storage Framework (SAF) compliance
      final prefs = await SharedPreferences.getInstance();
      final savedUri = prefs.getString('whatsapp_saf_uri');

      if (savedUri != null && await _safStream.isRootUriValid(savedUri)) {
        _fetchStatusesUsingSAF(savedUri);
      } else {
        _requestSAFDirectory();
      }
    } else {
      // Legacy Permission fallback for Android 10 and older devices
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();

      if (statuses[Permission.storage] == PermissionStatus.granted) {
        _fetchLegacyStatuses();
      } else {
        _showSnackBar("Storage permission is required to access media files.");
        setState(() => _loading = false);
      }
    }
  }

  // Opens Native OS Storage Framework panel explicitly targeting the WhatsApp folder
  Future<void> _requestSAFDirectory() async {
    try {
      const targetPath = "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses";
      String? selectedTreeUri = await _safStream.openDirectoryTree(initialUri: targetPath);

      if (selectedTreeUri != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('whatsapp_saf_uri', selectedTreeUri);
        _fetchStatusesUsingSAF(selectedTreeUri);
      } else {
        _showSnackBar("You must grant access to the folder to fetch media.");
        setState(() => _loading = false);
      }
    } catch (e) {
      _showSnackBar("Directory tracking handshake failed: \$e");
      setState(() => _loading = false);
    }
  }

  // Safely index files via content streams for modern devices
  Future<void> _fetchStatusesUsingSAF(String rootUri) async {
    try {
      final List<SafFileInfo> files = await _safStream.listDirectory(rootUri);
      setState(() {
        _statusFiles = files.where((file) {
          if (file.isDirectory) return false;
          final name = file.name.toLowerCase();
          return name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".mp4");
        }).toList();
      });
    } catch (e) {
      _showSnackBar("Failed to read items: \$e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Fallback engine tracker for older phone models
  Future<void> _fetchLegacyStatuses() async {
    try {
      const legacyPath = "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";
      final dir = Directory(legacyPath);
      if (await dir.exists()) {
        final List<FileSystemEntity> systemFiles = dir.listSync();
        setState(() {
          _statusFiles = systemFiles.map((f) => SafFileInfo(
            name: f.path.split('/').last,
            path: f.path,
            uri: Uri.file(f.path).toString(),
            isDirectory: false,
            lastModified: 0,
            size: 0,
          )).where((file) {
            final name = file.name.toLowerCase();
            return name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".mp4");
          }).toList();
        });
      } else {
        _showSnackBar("WhatsApp installation structure not found.");
      }
    } catch (e) {
      _showSnackBar("Legacy reader failed: \$e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🟢 Downloader processing module featuring ad trigger on completion
  Future<void> _saveToGallery(SafFileInfo file) async {
    try {
      _showSnackBar("Saving item...");
      
      // Cache binary stream data into system directories safely before moving to Photo Gallery
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('\({tempDir.path}/\){file.name}');
      
      if (file.path.isNotEmpty && await File(file.path).exists()) {
        await File(file.path).copy(tempFile.path);
      } else {
        final fileBytes = await _safStream.readFileBytes(file.uri);
        await tempFile.writeAsBytes(fileBytes);
      }

      if (file.name.toLowerCase().endsWith(".mp4")) {
        await Gal.putVideo(tempFile.path);
      } else {
        await Gal.putImage(tempFile.path);
      }
      
      _showSnackBar("Saved to Gallery! 🎉");
      _showInterstitialAd(); // 🟢 Trigger Full Screen Ad on successful save
      
    } catch (e) {
      _showSnackBar("Download failed: \$e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<String?> _getVideoThumbnail(SafFileInfo file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('\({tempDir.path}/thumb_\){file.name}');
      
      if (file.path.isNotEmpty) {
        return await VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 350,
          quality: 80,
        );
      }

      final fileBytes = await _safStream.readFileBytes(file.uri);
      await tempFile.writeAsBytes(fileBytes);

      return await VideoThumbnail.thumbnailFile(
        video: tempFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 350,
        quality: 80,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Status Downloader", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh List",
            onPressed: _checkPermissionsAndFetch,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _statusFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("No statuses found.", style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _checkPermissionsAndFetch,
