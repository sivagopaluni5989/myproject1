import "dart:io";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";
import "package:gal/gal.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Status Downloader",
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
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
  List<FileSystemEntity> _files = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (Platform.isAndroid) {
      await [Permission.storage, Permission.manageExternalStorage].request();
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final path = "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";
      final dir = Directory(path);
      if (await dir.exists()) {
        final list = dir.listSync();
        setState(() {
          _files = list.where((f) => f.path.endsWith(".jpg") || f.path.endsWith(".jpeg") || f.path.endsWith(".mp4")).toList();
        });
      } else {
        debugPrint("Directory not found");
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save(String filePath) async {
    try {
      if (filePath.endsWith(".mp4")) {
        await Gal.putVideo(filePath);
      } else {
        await Gal.putImage(filePath);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Gallery! 🎉")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Status Downloader"), backgroundColor: Colors.green, actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text("No statuses found. Please click refresh."))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: _files.length,
                  itemBuilder: (context, i) {
                    final f = _files[i];
                    final name = f.path.split("/").last;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: Colors.grey, child: Icon(name.endsWith(".mp4") ? Icons.play_circle : Icons.image, size: 50, color: Colors.white)),
                          Positioned(bottom: 0, left: 0, right: 0, child: Container(color: Colors.black54, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Padding(padding: const EdgeInsets.only(left: 4), child: Text(name, style: const TextStyle(color: Colors.white), maxLines: 1))), IconButton(icon: const Icon(Icons.download, color: Colors.greenAccent), onPressed: () => _save(f.path))])))
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
