import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:permission_handler/permission_handler.dart";
import "package:gal/gal.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Status Downloader",
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
  // Use a secure internal channel to read protected storage directory spaces
  static const PlatformMethodChannel = MethodChannel("com.example.status_downloader/storage");
  
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
      // ManageExternalStorage handles directory reading rights safely on Android 11+
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
                          Container(
                            color: Colors.black12,
                            child: Icon(
                              isVideo ? Icons.play_circle_filled : Icons.image, 
                              size: 60, 
                              color: isVideo ? Colors.redAccent : Colors.green,
                            ),
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
