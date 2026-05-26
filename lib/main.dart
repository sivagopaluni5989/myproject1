import "dart:io";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";
import "package:gal/gal.dart";
import "package:video_thumbnail/video_thumbnail.dart";
import "package:path_provider/path_provider.dart";

void main() => runApp(const MyApp());

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
    
  List<FileSystemEntity> _statusFiles = [];
  bool _loading = false;
  final String _whatsappPath = "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();
      
      if (statuses[Permission.manageExternalStorage] == PermissionStatus.granted || 
          statuses[Permission.storage] == PermissionStatus.granted) {
        _fetchStatuses();
      } else {
        _showSnackBar("Storage permissions are required to access statuses.");
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchStatuses() async {
    setState(() => _loading = true);
    try {
      final dir = Directory(_whatsappPath);
      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync();
        setState(() {
          _statusFiles = files.where((file) {
            final path = file.path.toLowerCase();
            return path.endsWith(".jpg") || path.endsWith(".jpeg") || path.endsWith(".mp4");
          }).toList();
        });
      } else {
        _showSnackBar("WhatsApp status folder not found on device.");
      }
    } catch (e) {
      _showSnackBar("Failed to load files: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveToGallery(String path) async {
    try {
      _showSnackBar("Saving item...");
      if (path.toLowerCase().endsWith(".mp4")) {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }
      _showSnackBar("Saved to Gallery! 🎉");
    } catch (e) {
      _showSnackBar("Download error: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<String?> _getVideoThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      return await VideoThumbnail.thumbnailFile(
        video: videoPath,
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
            tooltip: "Refresh",
            onPressed: _fetchStatuses,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _statusFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No statuses found.", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _checkPermissions,
                        icon: const Icon(Icons.security),
                        label: const Text("Retry Permissions Check"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 8, 
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _statusFiles.length,
                  itemBuilder: (context, i) {
                    final file = _statusFiles[i];
                    final name = file.path.split("/").last;
                    final isVideo = name.toLowerCase().endsWith(".mp4");
                    
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isVideo
                              ? FutureBuilder<String?>(
                                  future: _getVideoThumbnail(file.path),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(File(snapshot.data!), fit: BoxFit.cover),
                                          const Center(
                                            child: Icon(Icons.play_circle_filled, size: 50, color: Colors.white70),
                                          ),
                                        ],
                                      );
                                    }
                                    return const Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2));
                                  },
                                )
                              : Image.file(
                                  File(file.path),
                                  fit: BoxFit.cover,
                                  cacheWidth: 350,
                                  cacheHeight: 350,
                                ),
                          Positioned(
                            bottom: 0, 
                            left: 0, 
                            right: 0, 
                            child: Container(
                              color: Colors.black.withOpacity(0.60), 
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                children: [
                                  Expanded(
                                    child: Text(
                                      name, 
                                      style: const TextStyle(color: Colors.white, fontSize: 11), 
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.download, color: Colors.greenAccent, size: 26), 
                                    onPressed: () => _saveToGallery(file.path),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
