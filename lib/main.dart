import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

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
      title: 'Whatsapp Status Fast Downloader',
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

class _StatusScreenState extends State<StatusScreen> {
  List<FileSystemEntity> statusFiles = [];
  bool isLoading = true;
  BannerAd? bannerAd;
  bool adLoaded = false;

  @override
  void initState() {
    super.initState();
    loadBanner();
    getStatuses();
  }

  void loadBanner() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-3940256099942544/6300978111", 
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

  Future<void> getStatuses() async {
    setState(() {
      isLoading = true;
    });

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
          debugPrint("Directory access blocked by OS Scoped Storage. Requesting manual picker fallback.");
        }
      }
    }

    setState(() {
      statusFiles = temp;
      isLoading = false;
    });
  }

  Future<void> pickCustomDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      Directory dir = Directory(selectedDirectory);
      try {
        List<FileSystemEntity> files = dir.listSync().where((file) =>
            file.path.endsWith(".jpg") ||
            file.path.endsWith(".jpeg") ||
            file.path.endsWith(".png") ||
            file.path.endsWith(".mp4")).toList();
        setState(() {
          statusFiles = files;
        });
      } catch (e) {
        debugPrint("Error loading picked folder: $e");
      }
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
          SnackBar(content: Text("Error saving status: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget statusItem(FileSystemEntity file) {
    bool isVideo = file.path.endsWith(".mp4");
    return Card(
      child: Column(
        children: [
          Expanded(
            child: isVideo
                ? const Center(child: Icon(Icons.video_library, size: 80, color: Colors.green))
                : Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity),
          ),
          ElevatedButton.icon(
            onPressed: () => saveStatus(File(file.path)),
            icon: const Icon(Icons.download),
            label: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Whatsapp Status Fast Downloader"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: pickCustomDirectory,
            icon: const Icon(Icons.folder_open),
            tooltip: "Choose Manual Folder Path",
          ),
          IconButton(
            onPressed: getStatuses,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : statusFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No statuses found directly.", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: pickCustomDirectory,
                        icon: const Icon(Icons.folder),
                        label: const Text("Manually Select .Statuses Folder"),
                      ),
                    ],
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
                    return statusItem(statusFiles[index]);
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
