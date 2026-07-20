import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // Official Google test IDs
  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';

  // Your production IDs
  static const String _androidBannerProd =
      'ca-app-pub-8147663138065818/4787504382';

  static const String _androidInterstitialProd =
      'ca-app-pub-8147663138065818/1474146574';

  static String get bannerAdUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Only Android is supported.');
    }
    return kDebugMode ? _androidBannerTest : _androidBannerProd;
  }

  static String get interstitialAdUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Only Android is supported.');
    }
    return kDebugMode
        ? _androidInterstitialTest
        : _androidInterstitialProd;
  }
}
