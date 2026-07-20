import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const WAStatusSaverApp());
}

// ======================================================
// STATUS FILE MODEL
//
// All WhatsApp SAF files are copied into cache.
// The app will only work with cache paths.
// ======================================================

class StatusFile {
  final String name;

  final String cachePath;

  final bool isVideo;

  StatusFile({
    required this.name,
    required this.cachePath,
    required this.isVideo,
  });
}

// ======================================================
// APPLICATION CONSTANTS
// ======================================================

class AppConstants {
  static const String appName = "WA Status Fast Saver";

  static const Color primaryColor = Color(0xFF075E54);

  static const Color backgroundColor = Color(0xFFF5F5F5);

  static const String whatsappFolder =
      "Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  static const String businessFolder =
      "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";

  static const String saveAlbum = "WA Status Saver";
}

// ======================================================
// ROOT APPLICATION
// ======================================================

class WAStatusSaverApp extends StatelessWidget {
  const WAStatusSaverApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const HomeController(),
    );
  }
}

// ======================================================
// HOME CONTROLLER
//
// Responsible for:
// 1. Checking WhatsApp permissions
// 2. Showing authorization page
// 3. Opening status page
// ======================================================

class HomeController extends StatefulWidget {
  const HomeController({
    super.key,
  });

  @override
  State<HomeController> createState() => _HomeControllerState();
}

class _HomeControllerState extends State<HomeController> {
  bool isLoading = true;

  bool whatsappGranted = false;

  bool businessGranted = false;

  @override
  void initState() {
    super.initState();

    checkPermissions();
  }

  // ======================================================
  // Check existing SAF permissions
  // ======================================================

  Future<void> checkPermissions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final whatsappSaf = Saf(AppConstants.whatsappFolder);

      final businessSaf = Saf(AppConstants.businessFolder);

      whatsappGranted = await whatsappSaf.getDirectoryPermission(
            isDynamic: true,
          ) ??
          false;

      businessGranted = await businessSaf.getDirectoryPermission(
            isDynamic: true,
          ) ??
          false;

      debugPrint(
        "WhatsApp access: $whatsappGranted",
      );

      debugPrint(
        "Business access: $businessGranted",
      );
    } catch (e) {
      debugPrint(
        "Permission check failed: $e",
      );

      whatsappGranted = false;

      businessGranted = false;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading while checking permissions

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }

    // If any WhatsApp access exists
    // open main status page

    if (whatsappGranted || businessGranted) {
      return StatusHomePage(
        whatsappAccess: whatsappGranted,
        businessAccess: businessGranted,
      );
    }

    // Otherwise show authorization screen

    return AccessAuthorizationScreen(
      onPermissionGranted: () {
        checkPermissions();
      },
    );
  }
}
// ======================================================
// ACCESS AUTHORIZATION SCREEN
//
// Allows user to grant WhatsApp and Business
// status folder permissions using SAF
// ======================================================

class AccessAuthorizationScreen extends StatelessWidget {
  final VoidCallback onPermissionGranted;

  const AccessAuthorizationScreen({
    super.key,
    required this.onPermissionGranted,
  });

  // ======================================================
  // Request SAF folder permission
  // ======================================================

  Future<void> requestFolderAccess(
    BuildContext context,
    String folder,
    String name,
  ) async {
    try {
      final saf = Saf(folder);

      final granted = await saf.getDirectoryPermission(
            isDynamic: true,
          ) ??
          false;

      if (granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.primaryColor,
              content: Text(
                "$name access granted successfully",
              ),
            ),
          );
        }

        onPermissionGranted();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Folder access denied",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
        "SAF request failed: $e",
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unable to request folder permission",
            ),
          ),
        );
      }
    }
  }

  // ======================================================
  // WhatsApp / Business Access Card
  // ======================================================

  Widget buildAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String folder,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 55,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(
            height: 15,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Allow access to read and save WhatsApp statuses.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                requestFolderAccess(
                  context,
                  folder,
                  title,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(
                  0,
                  50,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(
                Icons.folder_open,
              ),
              label: const Text(
                "Grant Folder Access",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ======================================================
  // Screen UI
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "WA Status Fast Saver",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(
                height: 15,
              ),

              // Lock Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // Title
              const Text(
                "Access Authorization Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                "Grant access to WhatsApp folders to "
                "view, preview, and download your statuses.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // WhatsApp Access Card
              buildAccessCard(
                context,
                title: "WhatsApp",
                icon: Icons.chat,
                folder: AppConstants.whatsappFolder,
              ),

              // Business Access Card
              buildAccessCard(
                context,
                title: "WhatsApp Business",
                icon: Icons.business,
                folder: AppConstants.businessFolder,
              ),

              const SizedBox(
                height: 20,
              ),

              // Information Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(
                    color: Colors.green.shade300,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppConstants.primaryColor,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        "Open WhatsApp and watch some statuses first. "
                        "Only viewed statuses are available to save.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// STATUS HOME PAGE
//
// Handles:
// 1. WhatsApp / Business switching
// 2. Image & Video status lists
// 3. Cache-based StatusFile handling
// 4. Tab navigation
// 5. Loading state
// 6. AdMob banner
// ======================================================

class StatusHomePage extends StatefulWidget {
  final bool whatsappAccess;

  final bool businessAccess;

  const StatusHomePage({
    super.key,
    required this.whatsappAccess,
    required this.businessAccess,
  });

  @override
  State<StatusHomePage> createState() => _StatusHomePageState();
}

class _StatusHomePageState extends State<StatusHomePage>
    with TickerProviderStateMixin {
  // Current source
  // false = WhatsApp
  // true = Business

  bool isBusinessSelected = false;

  // WhatsApp statuses

  List<StatusFile> whatsappImages = [];

  List<StatusFile> whatsappVideos = [];

  // Business statuses

  List<StatusFile> businessImages = [];

  List<StatusFile> businessVideos = [];

  // Video thumbnail cache
  // Original cachePath -> thumbnail image path

  Map<String, String> videoThumbnails = {};

  // Page loading

  bool isLoading = true;

  // Tabs

  late TabController tabController;

  // AdMob

  BannerAd? bannerAd;

  bool adLoaded = false;

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 3,
      vsync: this,
    );

    initializeAds();

    requestPermissions();

    loadStatuses();
  }

  @override
  void dispose() {
    tabController.dispose();

    bannerAd?.dispose();

    super.dispose();
  }

  // ======================================================
  // AdMob Banner Initialization
  // ======================================================

  void initializeAds() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId:
          Platform.isAndroid ? "ca-app-pub-8147663138065818/2224393560" : "",
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              adLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (
          ad,
          error,
        ) {
          debugPrint(
            "Ad loading failed: $error",
          );

          ad.dispose();
        },
      ),
    );

    bannerAd!.load();
  }

  // ======================================================
  // Current visible images
  // ======================================================

  List<StatusFile> get currentImages {
    return isBusinessSelected ? businessImages : whatsappImages;
  }

  // ======================================================
  // Current visible videos
  // ======================================================

  List<StatusFile> get currentVideos {
    return isBusinessSelected ? businessVideos : whatsappVideos;
  }
  // ======================================================
  // Request media permissions
  // ======================================================

  Future<void> requestPermissions() async {
    try {
      await Permission.photos.request();

      await Permission.videos.request();

      await Permission.storage.request();
    } catch (e) {
      debugPrint(
        "Permission request failed: $e",
      );
    }
  }

  // ======================================================
  // Refresh all statuses
  // ======================================================

  Future<void> refreshStatuses() async {
    setState(() {
      isLoading = true;

      whatsappImages.clear();

      whatsappVideos.clear();

      businessImages.clear();

      businessVideos.clear();

      videoThumbnails.clear();
    });

    await clearTemporaryStatusCache();

    await loadStatuses();
  }

  // ======================================================
  // Load WhatsApp and Business statuses
  // ======================================================

  Future<void> loadStatuses() async {
    try {
      if (widget.whatsappAccess) {
        final waFiles = await loadFromSafFolder(
          AppConstants.whatsappFolder,
        );

        for (final file in waFiles) {
          if (file.isVideo) {
            whatsappVideos.add(file);
          } else {
            whatsappImages.add(file);
          }
        }
      }

      if (widget.businessAccess) {
        final wbFiles = await loadFromSafFolder(
          AppConstants.businessFolder,
        );

        for (final file in wbFiles) {
          if (file.isVideo) {
            businessVideos.add(file);
          } else {
            businessImages.add(file);
          }
        }
      }

      await generateVideoThumbnails();
    } catch (e) {
      debugPrint(
        "Status loading failed: $e",
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ======================================================
  // Clear temporary cached statuses
  //
  // Every refresh removes old copied files
  // and recreates fresh cache from SAF
  // ======================================================

  Future<void> clearTemporaryStatusCache() async {
    try {
      final cache = await getTemporaryDirectory();

      final files = cache.listSync();

      for (final file in files) {
        if (file is File && file.path.contains("wa_status_")) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint(
        "Cache cleanup error: $e",
      );
    }
  }

  // ======================================================
  // Read WhatsApp status folder using SAF
  //
  // Flow:
  // SAF Folder
  //      ↓
  // Get files
  //      ↓
  // Copy to temporary cache
  //      ↓
  // Return StatusFile objects
  // ======================================================

  Future<List<StatusFile>> loadFromSafFolder(
    String folder,
  ) async {
    List<StatusFile> statusFiles = [];

    try {
      final saf = Saf(folder);

      final permission = await saf.getDirectoryPermission(
            isDynamic: true,
          ) ??
          false;

      if (!permission) {
        debugPrint(
          "SAF permission missing: $folder",
        );

        return [];
      }

      final files = await saf.getFilesPath();

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(
               "Folder: $folder | Files: ${files?.length ?? 0}",
             ),
             duration: const Duration(seconds: 5),
           ),
         );
       }
      if (files != null && files.isNotEmpty && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(files.first.toString()),
             duration: const Duration(seconds: 10),
           ),
         );
       }

      if (files == null || files.isEmpty) {
         debugPrint("No status files found");
         return [];
      }
      


      final cacheDir = await getTemporaryDirectory();

      for (final originalPath in files) {
        try {
          final lower = originalPath.toLowerCase();

          final isImage = lower.endsWith(".jpg") ||
              lower.endsWith(".jpeg") ||
              lower.endsWith(".png");

          final isVideo = lower.endsWith(".mp4");

          if (!isImage && !isVideo) {
            continue;
          }

          final source = File(originalPath);

          final exists = await source.exists();

          debugPrint("Checking file: $originalPath");
          debugPrint("Exists: $exists");

// Skip inaccessible files
          if (!exists) {
           debugPrint(
             "Cannot access: $originalPath",
           );

           continue;
      }

          final extension = originalPath.split(".").last;

          final cachePath = "${cacheDir.path}/wa_status_"
              "${DateTime.now().microsecondsSinceEpoch}"
              ".$extension";

          final copied = await source.copy(
            cachePath,
          );

          statusFiles.add(
            StatusFile(
              name: copied.path.split("/").last,
              cachePath: copied.path,
              isVideo: isVideo,
            ),
          );
        } catch (e) {
          debugPrint(
            "Single file copy failed: $e",
          );
        }
      }

      debugPrint(
        "Loaded ${statusFiles.length} status files",
      );
    } catch (e) {
      debugPrint(
        "SAF loading error: $e",
      );
    }

    return statusFiles;
  }

  // ======================================================
  // Generate video thumbnails
  // ======================================================

  Future<void> generateVideoThumbnails() async {
    try {
      final videos = [
        ...whatsappVideos,
        ...businessVideos,
      ];

      final temp = await getTemporaryDirectory();

      for (final video in videos) {
        if (videoThumbnails.containsKey(
          video.cachePath,
        )) {
          continue;
        }

        final thumbnail = await VideoThumbnailPlus.thumbnailFile(
          video: video.cachePath,
          thumbnailPath: temp.path,
          imageFormat: ImageFormat.JPEG,
          quality: 80,
          maxWidth: 500,
        );

        if (thumbnail != null) {
          videoThumbnails[video.cachePath] = thumbnail;
        }
      }
    } catch (e) {
      debugPrint(
        "Thumbnail error: $e",
      );
    }
  }
  // ======================================================
  // Current selected status lists
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "WA Status Fast Saver",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              refreshStatuses();
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ====================================
          // WhatsApp / Business selector
          // ====================================

          Container(
            color: AppConstants.primaryColor,
            padding: const EdgeInsets.only(
              bottom: 12,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isBusinessSelected = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: !isBusinessSelected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        "WhatsApp",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isBusinessSelected
                              ? AppConstants.primaryColor
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isBusinessSelected = true;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isBusinessSelected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        "Business",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isBusinessSelected
                              ? AppConstants.primaryColor
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====================================
          // Images / Videos / Saved Tabs
          // ====================================

          TabBar(
            controller: tabController,
            labelColor: AppConstants.primaryColor,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppConstants.primaryColor,
            tabs: const [
              Tab(
                icon: Icon(
                  Icons.image,
                ),
                text: "Images",
              ),
              Tab(
                icon: Icon(
                  Icons.videocam,
                ),
                text: "Videos",
              ),
              Tab(
                icon: Icon(
                  Icons.download_done,
                ),
                text: "Saved",
              ),
            ],
          ),

          // ====================================
          // Main content area
          // ====================================

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  )
                : TabBarView(
                    controller: tabController,
                    children: [
                      // Images
                      buildStatusGrid(
                        currentImages,
                      ),

                      // Videos
                      buildStatusGrid(
                        currentVideos,
                      ),

                      // Saved
                      buildSavedPage(),
                    ],
                  ),
          ),

          // ====================================
          // AdMob Banner
          // ====================================

          if (adLoaded && bannerAd != null)
            SizedBox(
              height: bannerAd!.size.height.toDouble(),
              width: bannerAd!.size.width.toDouble(),
              child: AdWidget(
                ad: bannerAd!,
              ),
            ),
        ],
      ),
    );
  }
  // ======================================================
  // Status Grid
  //
  // Displays:
  // 1. Images using cachePath
  // 2. Video thumbnails
  // 3. Preview on click
  // 4. Download button
  // ======================================================

  Widget buildStatusGrid(
    List<StatusFile> files,
  ) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 90,
              color: Colors.grey.shade500,
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              "No Status Found",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Open WhatsApp and view some statuses.\nThen refresh this page.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final status = files[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewScreen(
                  status: status,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // =============================
                  // Image or video thumbnail
                  // =============================

                  status.isVideo
                      ? videoThumbnails.containsKey(
                          status.cachePath,
                        )
                          ? Image.file(
                              File(
                                videoThumbnails[status.cachePath]!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.black12,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            )
                      : Image.file(
                          File(
                            status.cachePath,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.broken_image,
                                size: 50,
                              ),
                            );
                          },
                        ),

                  // =============================
                  // Video play icon
                  // =============================

                  if (status.isVideo)
                    const Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                  // =============================
                  // Download button
                  // =============================

                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: InkWell(
                      onTap: () {
                        saveStatus(
                          status,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ======================================================
  // Save Status
  //
  // Saves cached image/video to Gallery
  // Fixes:
  // - Download button not working
  // - Android 11+ save failures
  // ======================================================

  Future<void> saveStatus(
    StatusFile status,
  ) async {
    try {
      bool success = false;

      if (status.isVideo) {
        success = await GallerySaver.saveVideo(
              status.cachePath,
              albumName: AppConstants.saveAlbum,
            ) ??
            false;
      } else {
        success = await GallerySaver.saveImage(
              status.cachePath,
              albumName: AppConstants.saveAlbum,
            ) ??
            false;
      }

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppConstants.primaryColor,
            content: Text(
              "Status downloaded successfully",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Failed to save status",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        "Save status error: $e",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Save failed: $e",
            ),
          ),
        );
      }
    }
  }

  // ======================================================
  // Load saved files from WA Status Saver album
  // ======================================================

  Future<List<File>> getSavedFiles() async {
    try {
      final storage = await getExternalStorageDirectory();

      if (storage == null) {
        return [];
      }

      // Android Pictures directory
      final saveFolder = Directory(
        "${storage.parent.parent.parent.parent.path}"
        "/Pictures/${AppConstants.saveAlbum}",
      );

      if (!await saveFolder.exists()) {
        return [];
      }

      final files = saveFolder.listSync().whereType<File>().where((file) {
        final name = file.path.toLowerCase();

        return name.endsWith(".jpg") ||
            name.endsWith(".jpeg") ||
            name.endsWith(".png") ||
            name.endsWith(".mp4");
      }).toList();

      // Latest files first
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(
              a.lastModifiedSync(),
            ),
      );

      return files;
    } catch (e) {
      debugPrint(
        "Saved status loading error: $e",
      );

      return [];
    }
  }
  // ======================================================
  // Saved Status Page
  //
  // Shows downloaded statuses from Gallery folder
  // ======================================================

  Widget buildSavedPage() {
    return FutureBuilder<List<File>>(
      future: getSavedFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppConstants.primaryColor,
            ),
          );
        }

        final files = snapshot.data ?? [];

        // No saved statuses
        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_done,
                  size: 90,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  "No Saved Status",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Downloaded statuses will appear here",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        // Saved status grid

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: files.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final file = files[index];

            final isVideo = file.path.toLowerCase().endsWith(".mp4");

            final status = StatusFile(
              name: file.path.split("/").last,
              cachePath: file.path,
              isVideo: isVideo,
            );

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreviewScreen(
                      status: status,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image preview

                      if (!isVideo)
                        Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.broken_image,
                                size: 50,
                              ),
                            );
                          },
                        )

                      // Video preview

                      else
                        Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.black54,
                              size: 60,
                            ),
                          ),
                        ),

                      // Video play overlay

                      if (isVideo)
                        const Center(
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ======================================================
// PREVIEW SCREEN
//
// Features:
// 1. Full image preview
// 2. Image zoom support
// 3. Video playback
// 4. Play/Pause control
// ======================================================

class PreviewScreen extends StatefulWidget {
  final StatusFile status;

  const PreviewScreen({
    super.key,
    required this.status,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  VideoPlayerController? controller;

  bool isVideoReady = false;

  @override
  void initState() {
    super.initState();

    if (widget.status.isVideo) {
      initializeVideo();
    }
  }

  Future<void> initializeVideo() async {
    try {
      controller = VideoPlayerController.file(
        File(
          widget.status.cachePath,
        ),
      );

      await controller!.initialize();

      controller!.setLooping(true);

      controller!.play();

      if (mounted) {
        setState(() {
          isVideoReady = true;
        });
      }
    } catch (e) {
      debugPrint(
        "Video initialization failed: $e",
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          widget.status.isVideo ? "Video Preview" : "Image Preview",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: widget.status.isVideo
            ? isVideoReady
                ? AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: VideoPlayer(
                      controller!,
                    ),
                  )
                : const CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  )
            : InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.file(
                  File(
                    widget.status.cachePath,
                  ),
                  fit: BoxFit.contain,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 70,
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            "Unable to open image",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: widget.status.isVideo && isVideoReady
          ? FloatingActionButton(
              backgroundColor: AppConstants.primaryColor,
              onPressed: () {
                setState(() {
                  if (controller!.value.isPlaying) {
                    controller!.pause();
                  } else {
                    controller!.play();
                  }
                });
              },
              child: Icon(
                controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
