
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.green,
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

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> generalFiles = [];
  List<String> businessFiles = [];

  Map<String, String> videoThumbnails = {};

  bool isLoading = false;

  BannerAd? bannerAd;
  bool adLoaded = false;

  final String legacyGeneralPath =
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';

  final String legacyOldGeneralPath =
      '/storage/emulated/0/WhatsApp/Media/.Statuses';

  final String legacyBusinessPath =
      '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';

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
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            adLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
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
    setState(() {
      isLoading = true;
    });

    int sdkInt = await _getAndroidSDK();

    if (sdkInt >= 33) {
      await [
        Permission.photos,
        Permission.videos,
      ].request();
    } else {
      await Permission.storage.request();
    }

    generalFiles = _loadLegacyFiles(
      legacyGeneralPath,
      legacyOldGeneralPath,
    );

    businessFiles = _loadLegacyFiles(
      legacyBusinessPath,
      '',
    );

    setState(() {
      isLoading = false;
    });

    generateAllThumbnails([
      ...generalFiles,
      ...businessFiles,
    ]);
  }

  List<String> _loadLegacyFiles(
    String primaryPath,
    String fallbackPath,
  ) {
    List<String> results = [];

    Directory dir = Directory(primaryPath);

    if (!dir.existsSync() && fallbackPath.isNotEmpty) {
      dir = Directory(fallbackPath);
    }

    if (dir.existsSync()) {
      try {
        results = dir
            .listSync()
            .map((item) => item.path)
            .where(
              (path) =>
                  !path.contains('.nomedia') &&
                  (
                    path.endsWith('.jpg') ||
                    path.endsWith('.jpeg') ||
                    path.endsWith('.png') ||
                    path.endsWith('.mp4')
                  ),
            )
            .toList();
      } catch (e) {
        debugPrint('Storage scan error: $e');
      }
    }

    return results;
  }

  Future<void> generateAllThumbnails(List<String> files) async {
    try {
      final tempDir = await getTemporaryDirectory();

      for (var path in files) {
        if (
            path.endsWith('.mp4') &&
            !videoThumbnails.containsKey(path)
        ) {
          final thumbnailPath =
              await VideoThumbnailPlus.thumbnailFile(
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
      debugPrint('Thumbnail generation error: $e');
    }
  }

  Future<void> saveStatus(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found');
      }

      Directory targetDir;

      if (filePath.endsWith('.mp4')) {
        targetDir = Directory(
          '/storage/emulated/0/Movies/StatusSaver',
        );
      } else {
        targetDir = Directory(
          '/storage/emulated/0/Pictures/StatusSaver',
        );
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() +
              (filePath.endsWith('.mp4') ? '.mp4' : '.jpg');

      final savedFile = await file.copy(
        '${targetDir.path}/$fileName',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${savedFile.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
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
          padding: EdgeInsets.all(24),
          child: Text(
            'No statuses found.\n\nOpen WhatsApp and watch statuses first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: files.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final path = files[index];

        bool isVideo = path.endsWith('.mp4');

        String? videoThumb = videoThumbnails[path];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          child: Column(
            children: [
              Expanded(
                child: isVideo
                    ? (
                        videoThumb != null
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.file(
                                    File(videoThumb),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  const CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child:
                                    CircularProgressIndicator(),
                              )
                      )
                    : Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: () {
                    saveStatus(path);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(
                    Icons.download,
                    size: 16,
                  ),
                  label: const Text('Save'),
                ),
              ),
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
        backgroundColor: Colors.green,
        title: const Text(
          'WhatsApp Status Saver',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.chat),
              text: 'WhatsApp',
            ),
            Tab(
              icon: Icon(Icons.business),
              text: 'Business',
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                buildGrid(generalFiles),
                buildGrid(businessFiles),
              ],
            ),
      bottomNavigationBar: adLoaded
          ? SizedBox(
              height: bannerAd!.size.height.toDouble(),
              width: bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: bannerAd!),
            )
          : null,
    );
  }
}
