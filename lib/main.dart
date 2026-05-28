import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saf/saf.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

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

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> generalFiles = [];
  List<String> businessFiles = [];

  Map<String, String> videoThumbnails = {};

  bool isLoading = false;

  BannerAd? bannerAd;

  bool adLoaded = false;

  final String whatsappPath =
      'Android/media/com.whatsapp/WhatsApp/Media/.Statuses';

  final String businessPath =
      'Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    loadBanner();

    loadStatuses();
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
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );

    bannerAd!.load();
  }

  Future<void> loadStatuses() async {
    setState(() {
      isLoading = true;
    });

    await Permission.photos.request();
    await Permission.videos.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    generalFiles = await loadSafFiles(whatsappPath);

    businessFiles = await loadSafFiles(businessPath);

    await generateAllThumbnails([
      ...generalFiles,
      ...businessFiles,
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<List<String>> loadSafFiles(String path) async {
    try {
      final saf = Saf(path);

      bool? permission = await saf.getDirectoryPermission(
        isDynamic: false,
      );

      if (permission == true) {
        List<String>? files = await saf.getFilesPath();

        if (files != null) {
          return files.where((file) {
            return file.endsWith('.jpg') ||
                file.endsWith('.jpeg') ||
                file.endsWith('.png') ||
                file.endsWith('.mp4');
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("SAF ERROR: $e");
    }

    return [];
  }

  Future<void> generateAllThumbnails(List<String> files) async {
    try {
      final tempDir = await getTemporaryDirectory();

      for (var path in files) {
        if (path.endsWith('.mp4')) {
          if (!videoThumbnails.containsKey(path)) {
            final thumb =
                await VideoThumbnailPlus.thumbnailFile(
              video: path,
              thumbnailPath: tempDir.path,
              imageFormat: ImageFormat.JPEG,
              quality: 75,
              maxWidth: 300,
            );

            if (thumb != null) {
              videoThumbnails[path] = thumb;
            }
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
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

    final savedPath = '${targetDir.path}/$fileName';

    final savedFile = await file.copy(savedPath);

    // AUTO REFRESH GALLERY
    if (filePath.endsWith('.mp4')) {
      await GallerySaver.saveVideo(savedFile.path);
    } else {
      await GallerySaver.saveImage(savedFile.path);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved Successfully'),
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
          padding: EdgeInsets.all(20),
          child: Text(
            'No statuses found.\n\nOpen WhatsApp and watch statuses first.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
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

        return Card(
          child: Column(
            children: [
              Expanded(
                child: isVideo
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          videoThumbnails[path] != null
                              ? Image.file(
                                  File(videoThumbnails[path]!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : const Center(
                                  child:
                                      CircularProgressIndicator(),
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
                    : Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  saveStatus(path);
                },
                icon: const Icon(Icons.download),
                label: const Text('Save'),
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
        title: const Text(
          'WhatsApp Status Saver',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
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
