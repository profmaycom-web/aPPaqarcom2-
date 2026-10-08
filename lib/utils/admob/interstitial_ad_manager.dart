import 'dart:io';

import 'package:ebroker/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  static int _adCount = 0;
  static InterstitialAd? _interstitialAd;

  Future<void> load({VoidCallback? onAdLoad}) async {
    if (!AppSettings.isAdmobAdsEnabled) {
      return;
    }

    await InterstitialAd.load(
      adUnitId: (Platform.isAndroid
          ? AppSettings.admobInterstitialAndroid
          : AppSettings.admobInterstitialIos),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          onAdLoad?.call();
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  Future<void> show() async {
    if (!AppSettings.isAdmobAdsEnabled) {
      return;
    }
    if (_interstitialAd != null) {
      _adCount++;
      if (_adCount == 4) {
        await _interstitialAd!.show();

        _adCount = 0; // Reset the count after showing the ad
      }
    }
  }
}
