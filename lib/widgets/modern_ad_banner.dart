import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

class ModernAdBanner extends StatefulWidget {
  const ModernAdBanner({super.key});

  @override
  State<ModernAdBanner> createState() => _ModernAdBannerState();
}

class _ModernAdBannerState extends State<ModernAdBanner> {
  bool _unityBannerLoaded = false;

  void _showCustomAdPopup() async {
    final Uri url = Uri.parse('https://mallinorois.com/'); // 🔁 Your target URL
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child:
          _unityBannerLoaded
              ? UnityBannerAd(
                placementId: 'Banner_Android',
                onLoad: (placementId) {
                  debugPrint('✅ Banner loaded: $placementId');
                  setState(() {
                    _unityBannerLoaded = true;
                  });
                },
                onClick:
                    (placementId) =>
                        debugPrint('👉 Banner clicked: $placementId'),
                onFailed: (placementId, error, message) {
                  debugPrint(
                    '❌ Banner failed: $placementId | $error | $message',
                  );
                  setState(() {
                    _unityBannerLoaded = false;
                  });
                },
              )
              : GestureDetector(
                onTap: _showCustomAdPopup,
                child: Image.asset(
                  'assets/images/custom_banner.png',
                  fit: BoxFit.cover,
                ),
              ),
    );
  }
}
