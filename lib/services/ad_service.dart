import 'package:flutter/material.dart';

class AdService {
  static OverlayEntry? _bannerOverlayEntry;

  static Future<void> initialize() async {
    print('Dummy AdService initialized');
  }

  static void showBannerAd(BuildContext context) {
    if (_bannerOverlayEntry != null) return; // Banner already shown

    _bannerOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.blueGrey,
          height: 50,
          child: const Center(
            child: Text(
              'Dummy Banner Ad',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_bannerOverlayEntry!);
    print('Dummy banner ad shown');
  }

  static void hideBannerAd() {
    _bannerOverlayEntry?.remove();
    _bannerOverlayEntry = null;
    print('Dummy banner ad hidden');
  }

  static void loadInterstitialAd(String adUnitId) {
    print('Dummy interstitial ad loaded for adUnitId: $adUnitId');
  }

  static void showInterstitialAd(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dummy Interstitial Ad'),
        content: const Text('This is a dummy interstitial ad.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              print('Dummy interstitial ad closed');
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
    print('Dummy interstitial ad shown');
  }

  static void loadRewardedAd(String adUnitId) {
    print('Dummy rewarded ad loaded for adUnitId: $adUnitId');
  }

  static void showRewardedAd(BuildContext context, Function onRewarded) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dummy Rewarded Ad'),
        content: const Text('This is a dummy rewarded ad.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRewarded();
              print('Dummy rewarded ad closed and reward granted');
            },
            child: const Text('Claim Reward'),
          ),
        ],
      ),
    );
    print('Dummy rewarded ad shown');
  }
}
