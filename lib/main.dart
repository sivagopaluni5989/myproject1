import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'package:path_provider/path_provider.dart';

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

class _StatusScreenState extends State<StatusScreen> {
  List<FileSystemEntity> statusFiles = [];
  Map<String, String> videoThumbnails = {}; 
  bool isLoading = true;
  BannerAd? bannerAd;
  bool adLoaded = false;

  @override
  void initState() {
    super.initState();
    loadBanner();
    autoRequestAndLoad();
  }

  void loadBanner() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-3940256099942544/6300978111", 
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => adLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
      request: const AdRequest(),
    );
    bannerAd!.load();
  }

  Future<void> autoRequestAndLoad() async {
    setState(() => isLoading = true);

    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }

    List<String> paths = [
      "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
      "/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses",
      "/storage/emulated/0/WhatsApp/Media/.Statuses"
    ];

    List<FileSystemEntity> temp = [];

    for (String path in paths) {
      Directory dir = Directory(path);
      if (await dir.exists()) {
        try {
          temp.addAll(
            dir.listSync().where((file) =>
                !file.path.contains(".nomedia") &&
                (file.path.endsWith(".jpg") ||
                    file.path.endsWith(".jpeg") ||
                    file.path.endsWith(".png") ||
                    file.path.endsWith(".mp4"))),
          );
        } catch (e) {
          debugPrint("Folder reading blocked: $e");
        }
      }
    }

    setState(() {
      statusFiles = temp;
      isLoading = false;
    });

    generateAllThumbnails();
  }

  Future<void> generateAllThumbnails() async {
    try {
      final tempDir = await getTemporaryDirectory();
      for (var file in statusFiles) {
        if (file.path.endsWith(".mp4")) {
          // Changed VideoThumbnail to VideoThumbnailPlus to match package ^0.0.2
          final thumbnailPath = await VideoThumbnailPlus.thumbnailFile(
            video: file.path,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 300, 
            quality: 75,
          );
          if (thumbnailPath != null && mounted) {
            setState(() {
              videoThumbnails[file.path] = thumbnailPath;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error creating video frame: $e");
    }
  }

  Future<void> saveStatus(File file) async {
    try {
      Directory saveDir = Directory("/storage/emulated/0/Download/SavedStatuses");
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      String filename = file.uri.pathSegments.last;
      File newFile = File("${saveDir.path}/$filename");
      await newFile.writeAsBytes(await file.readAsBytes());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved to Download/SavedStatuses")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Perfect center layout alignment
        title: const Text(
          "WhatsApp Status Saver",
          style: TextStyle(
            fontWeight: FontWeight.bold, // Bold and stylish typography
            fontSize: 22,
            letterSpacing: 0.8,
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: autoRequestAndLoad,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : statusFiles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "No statuses found.\n\nMake sure to watch statuses inside the official WhatsApp application first!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: statusFiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final file = statusFiles[index];
                    bool isVideo = file.path.endsWith(".mp4");
                    String? videoThumb = videoThumbnails[file.path];

                    return Card(
                      clipBehavior: Clip.antiAlias,
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
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Colors.black45, 
                                              shape: BoxShape.circle
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow, 
                                              size: 36, 
                                              color: Colors.white
                                            ),
                                          )
                                        ],
                                      )
                                    : const Center(child: CircularProgressIndicator()))
                                : Image.file(
                                    File(file.path), 
                                    fit: BoxFit.cover, 
                                    width: double.infinity, 
                                    height: double.infinity
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ElevatedButton.icon(
                              onPressed: () => saveStatus(File(file.path)),
                              icon: const Icon(Icons.download),
                              label: const Text("Save"),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: adLoaded
          ? SizedBox(
              height: bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: bannerAd!),
            )
          : null,
    );
  }
}
