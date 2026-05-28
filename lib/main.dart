import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:gal/gal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WhatsApp Status Saver',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const StatusScreen(),
    );
  }
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<String> generalFiles = [];
  List<String> businessFiles = [];
  Map<String, String> videoThumbnails = {}; 
  bool isLoading = false;
  BannerAd? bannerAd;
  bool adLoaded = false;

  final String safGeneralPath = "Android/media/com.whatsapp/WhatsApp/Media/.Statuses";
  final String safBusinessPath = "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";

  final String legacyGeneralPath = "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";
  final String legacyOldGeneralPath = "/storage/emulated/0/WhatsApp/Media/.Statuses";
  final String legacyBusinessPath = "/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadBanner();
    autoRequestAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    bannerAd?.dispose();
    super.dispose();
  }

  void loadBanner() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-3940256099942544/6300978111", 
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => adLoaded = true),
        onAdFailedToLoad: (ad, error) {
          debugPrint("Ad failed to mount: \$error");
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );
    bannerAd!.load();
  }

  Future<int> _getAndroidSDK() async {
    if (Platform.isAndroid) {
      final versionString = Platform.operatingSystemVersion;
      final match = RegExp(r'API\s+(\d+)').firstMatch(versionString);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return 30; 
  }

  Future<void> autoRequestAndLoad() async {
    setState(() => isLoading = true);

    int sdkInt = await _getAndroidSDK();

    if (sdkInt < 30) {
      if (await Permission.storage.request().isGranted) {
        generalFiles = _loadLegacyFiles(legacyGeneralPath, legacyOldGeneralPath);
        businessFiles = _loadLegacyFiles(legacyBusinessPath, "");
      }
    } else {
      generalFiles = await _loadSafFiles(safGeneralPath);
      businessFiles = await _loadSafFiles(safBusinessPath);
    }

    setState(() => isLoading = false);
    generateAllThumbnails([...generalFiles, ...businessFiles]);
  }

  List<String> _loadLegacyFiles(String primaryPath, String fallbackPath) {
    List<String> results = [];
    Directory dir = Directory(primaryPath);
    if (!dir.existsSync() && fallbackPath.isNotEmpty) {
      dir = Directory(fallbackPath);
    }

    if (dir.existsSync()) {
      try {
        results = dir.listSync()
            .map((item) => item.path)
            .where((path) =>
                !path.contains(".nomedia") &&
                (path.endsWith(".jpg") || path.endsWith(".jpeg") || path.endsWith(".png") || path.endsWith(".mp4")))
            .toList();
      } catch (e) {
        debugPrint("Direct filesystem parsing failure: \$e");
      }
    }
    return results;
  }

    Future<List<String>> _loadSafFiles(String safPathSegment) async {
    try {
      Saf safInstance = Saf(safPathSegment);
      bool? permissionGranted = await safInstance.getDirectoryPermission();

      if (permissionGranted == true) {
        List<String>? cachedPaths = await safInstance.getFilesPath();
        if (cachedPaths != null) {
          // Convert file schema elements directly to clean local strings
          return cachedPaths
              .map((path) => Uri.parse(path).path)
              .where((path) =>
                  !path.contains(".nomedia") &&
                  (path.endsWith(".jpg") || path.endsWith(".jpeg") || path.endsWith(".png") || path.endsWith(".mp4")))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("SAF extraction sequence fault: $e");
    }
    return [];
  }


  Future<void> generateAllThumbnails(List<String> files) async {
    try {
      final tempDir = await getTemporaryDirectory();
      for (var path in files) {
        if (path.endsWith(".mp4") && !videoThumbnails.containsKey(path)) {
          final thumbnailPath = await VideoThumbnailPlus.thumbnailFile(
            video: path,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 300, 
            quality: 75,
          );
          if (thumbnailPath != null && mounted) {
            setState(() {
              videoThumbnails[path] = thumbnailPath;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Video frame decode exception: \$e");
    }
  }

    Future<void> saveStatus(String filePath) async {
    try {
      // Direct permission handling via gal package structure requirement
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      if (filePath.endsWith(".mp4")) {
        await Gal.putVideo(filePath);
      } else {
        await Gal.putImage(filePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved directly into your device Gallery app!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // FIXED: Removed the backslash so it displays the real system error message
            content: Text("Gallery Save Failure: $error"), 
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget buildGrid(List<String> files) {
    if (files.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "No statuses found.\n\nOpen WhatsApp and view your statuses completely first!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final path = files[index];
        bool isVideo = path.endsWith(".mp4");
        String? videoThumb = videoThumbnails[path];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          child: Column(
            children: [
              Expanded(
                child: isVideo
                    ? (videoThumb != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.file(
                                File(videoThumb), 
                                fit: BoxFit.cover, 
                                width: double.infinity, 
                                height: double.infinity
                              ),
                              const CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.play_arrow, color: Colors.white),
                              )
                            ],
                          )
                        : const Center(child: CircularProgressIndicator()))
                    : Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton.icon(
                  onPressed: () => saveStatus(path),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text("Save"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "WhatsApp Status Saver",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: "WhatsApp"),
            Tab(icon: Icon(Icons.business), text: "WA Business"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: autoRequestAndLoad,
            icon: const Icon(Icons.refresh, color: Colors.white),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      buildGrid(generalFiles),
                      buildGrid(businessFiles),
                    ],
                  ),
          ),
          if (adLoaded && bannerAd != null)
            SafeArea(
              child: SizedBox(
                width: bannerAd!.size.width.toDouble(),
                height: bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}
