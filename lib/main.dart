import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  List<FileSystemEntity> statusFiles = [];

  bool isLoading = true;

  BannerAd? bannerAd;

  bool isBannerLoaded = false;

  final String statusPath =
      "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  @override
  void initState() {
    super.initState();

    loadStatuses();

    loadBannerAd();
  }

  void loadBannerAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,

      // Replace with your real AdMob Banner ID
      adUnitId: BannerAd.testAdUnitId,

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            isBannerLoaded = true;
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
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    final dir = Directory(statusPath);

    if (await dir.exists()) {
      statusFiles = dir.listSync().where((file) {
        return file.path.endsWith(".jpg") ||
            file.path.endsWith(".jpeg") ||
            file.path.endsWith(".png") ||
            file.path.endsWith(".mp4");
      }).toList();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveFile(File file) async {
    final extDir = await getExternalStorageDirectory();

    if (extDir == null) return;

    final saveDir = Directory("${extDir.path}/SavedStatuses");

    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final newFile = File(
      "${saveDir.path}/${file.uri.pathSegments.last}",
    );

    await newFile.writeAsBytes(await file.readAsBytes());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saved successfully"),
        ),
      );
    }
  }

  Widget buildItem(FileSystemEntity file) {
    final bool isVideo = file.path.endsWith(".mp4");

    return Card(
      elevation: 4,
      child: Column(
        children: [
          Expanded(
            child: isVideo
                ? const Center(
                    child: Icon(
                      Icons.video_library,
                      size: 80,
                    ),
                  )
                : Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: () {
                saveFile(File(file.path));
              },
              icon: const Icon(Icons.download),
              label: const Text("Save"),
            ),
          ),
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
        actions: [
          IconButton(
            onPressed: loadStatuses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : statusFiles.isEmpty
              ? const Center(
                  child: Text(
                    "No statuses found",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: statusFiles.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    return buildItem(statusFiles[index]);
                  },
                ),

      bottomNavigationBar: isBannerLoaded
          ? SizedBox(
              height: bannerAd!.size.height.toDouble(),
              width: bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: bannerAd!),
            )
          : null,
    );
  }
}
