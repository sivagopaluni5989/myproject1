import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:saf/saf.dart'; 

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

class _StatusScreenState extends State<StatusScreen> {
  List<String> statusFiles = [];
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

    List<String> temp = [];

    for (String path in paths) {
      Directory dir = Directory(path);
      if (await dir.exists()) {
        try {
          final files = dir.listSync().map((f) => f.path).where((filePath) =>
              !filePath.contains(".nomedia") &&
              (filePath.endsWith(".jpg") ||
                  filePath.endsWith(".jpeg") ||
                  filePath.endsWith(".png") ||
                  filePath.endsWith(".mp4")));
          temp.addAll(files);
        } catch (e) {
          debugPrint("Scoped Storage Blocked Direct Path Access.");
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
      setState(() {
        isLoading = true;
      });
      try {
        // Initialize SAF properly for 1.0.4 API semantics
        Saf saf = Saf(selectedDirectory);
        
        // request permission with the correct method name mapping
        bool? isGranted = await saf.getDirectoryPermission(isDynamic: true);
        
        if (isGranted == true) {
          // Sync files cache natively
          await saf.sync();
          
          // Fetch strings path mapping matching version 1.0.4
          List<String>? cachedPaths = await saf.getCachedFilesPath();
          
          if (cachedPaths != null) {
            List<String> filteredFiles = cachedPaths.where((filePath) =>
                filePath.toLowerCase().endsWith(".jpg") ||
                filePath.toLowerCase().endsWith(".jpeg") ||
                filePath.toLowerCase().endsWith(".png") ||
                filePath.toLowerCase().endsWith(".mp4")).toList();
            
            setState(() {
              statusFiles = filteredFiles;
            });
          }
        }
      } catch (e) {
        debugPrint("SAF Reading Error: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveStatus(String filePath) async {
    try {
      Directory saveDir = Directory("/storage/emulated/0/Download/SavedStatuses");
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      String filename = filePath.split('/').last;
      File newFile = File("${saveDir.path}/$filename");
      
      File sourceFile = File(filePath);
      await newFile.writeAsBytes(await sourceFile.readAsBytes());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved to Download/SavedStatuses")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget statusItem(String filePath) {
    bool isVideo = filePath.toLowerCase().endsWith(".mp4");
    return Card(
      child: Column(
        children: [
          Expanded(
            child: isVideo
                ? const Center(child: Icon(Icons.video_library, size: 80, color: Colors.green))
                : Image.file(File(filePath), fit: BoxFit.cover, width: double.infinity),
          ),
          ElevatedButton.icon(
            onPressed: () => saveStatus(filePath),
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
        title: const Text("WhatsApp Status Saver"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
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
                      const Text(
                        "No statuses found",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: pickCustomDirectory,
                        icon: const Icon(Icons.folder_open, color: Colors.white),
                        label: const Text(
                          "Grant WhatsApp Folder Permission",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
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
