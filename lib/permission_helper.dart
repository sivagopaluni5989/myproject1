import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StatusPermissionHelper {
  Future<bool> requestStatusAccessWorkflow() async {
    if (!Platform.isAndroid) return false;

    final info = await DeviceInfoPlugin().androidInfo;

    if (info.version.sdkInt >= 33) {
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();

      return photos.isGranted || videos.isGranted;
    } else {
      return (await Permission.storage.request()).isGranted;
    }
  }
}
