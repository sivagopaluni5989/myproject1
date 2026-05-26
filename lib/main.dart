import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() {
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
  final SafStream _safStream = SafStream();

  List<SafFileInfo> _statusFiles = [];

  bool _isLoading = false;

  static const String whatsappStatusPath =
      'Android/media/com.whatsapp/WhatsApp/Media/.Statuses';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndFetch();
  }

  Future<void> _checkPermissionsAndFetch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      PermissionStatus storage = await Permission.storage.request();

      if (!storage.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied'),
            ),
          );
        }

        setState(() {
          _isLoading = false;
        });

        return;
      }

      await _pickWhatsAppFolder();
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickWhatsAppFolder() async {
    try {
      String? treeUri = await _safStream.openDirectoryTree(
        initialUri: whatsappStatusPath,
      );

      if (treeUri == null) {
        return;
      }

      final List<SafFileInfo> files =
          await _safStream.listDirectory(treeUri);

      final filtered = files.where((file) {
        if (file.isDirectory) {
          return false;
        }

        final name = file.name.toLowerCase();

        return name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png') ||
            name.endsWith('.mp4');
      }).toList();

      setState(() {
        _statusFiles = filtered;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _saveToGallery(SafFileInfo file) async {
    try {
      final Uint8List? bytes = await _safStream.readFile(file.uri);

      if (bytes == null) {
        return;
      }

      final Directory? dir = await getExternalStorageDirectory();

      if (dir == null) {
        return;
      }

      final saveDir = Directory('${dir.path}/SavedStatuses');

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final newFile = File('${saveDir.path}/${file.name}');

      await newFile.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} saved'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> _getVideoThumbnail(SafFileInfo file) async {
    try {
      final Uint8List? bytes = await _safStream.readFile(file.uri);

      if (bytes == null) {
        return null;
      }

      final Directory tempDir = await getTemporaryDirectory();

      final tempVideo = File('${tempDir.path}/${file.name}');

      await tempVideo.writeAsBytes(bytes);

      return await VideoThumbnail.thumbnailFile(
        video: tempVideo.path,
        imageFormat: ImageFormat.PNG,
        quality: 75,
      );
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Widget _buildImageCard(SafFileInfo file) {
    return FutureBuilder<Uint8List?>(
      future: _safStream.readFile(file.uri),
      builder: (context, snapshot) {
        Widget preview = const Center(
          child: CircularProgressIndicator(),
        );

        if (snapshot.hasData) {
          preview = Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }

        return Card(
          elevation: 4,
          child: Column(
            children: [
              Expanded(
                child: preview,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  onPressed: () => _saveToGallery(file),
                  icon: const Icon(Icons.download),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoCard(SafFileInfo file) {
    return FutureBuilder<String?>(
      future: _getVideoThumbnail(file),
      builder: (context, snapshot) {
        Widget preview = Container(
          color: Colors.black12,
          child: const Center(
            child: Icon(
              Icons.videocam,
              size: 60,
            ),
          ),
        );

        if (snapshot.hasData && snapshot.data != null) {
          preview = Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(snapshot.data!),
                fit: BoxFit.cover,
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ],
          );
        }

        return Card(
          elevation: 4,
          child: Column(
            children: [
              Expanded(
                child: preview,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  onPressed: () => _saveToGallery(file),
                  icon: const Icon(Icons.download),
                  label: const Text('Save'),
                ),
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
        title: const Text('WhatsApp Status Saver'),
        actions: [
          IconButton(
            onPressed: _checkPermissionsAndFetch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _statusFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No statuses found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _checkPermissionsAndFetch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _statusFiles.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final file = _statusFiles[index];

                    final name = file.name.toLowerCase();

                    if (name.endsWith('.mp4')) {
                      return _buildVideoCard(file);
                    }

                    return _buildImageCard(file);
                  },
                ),
    );
  }
}
