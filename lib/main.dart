import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  final String statusPath =
      "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  @override
  void initState() {
    super.initState();
    loadStatuses();
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
          content: Text("Saved"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WhatsApp Status Saver"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              itemCount: statusFiles.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                final file = statusFiles[index];

                return Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: file.path.endsWith(".mp4")
                            ? const Icon(
                                Icons.video_library,
                                size: 80,
                              )
                            : Image.file(
                                File(file.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          saveFile(File(file.path));
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
