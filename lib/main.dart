import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'providers/favorites_provider.dart';
import 'pages/home_page.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UnityAds.init(
    gameId: '5899030', // Android Game ID
    testMode: false,
  );

  await checkAppVersion();
  await trackInstallIfFirstTime();

  runApp(const MyApp());
}

Future<void> checkAppVersion() async {
  const apiUrl = 'https://api-15hv.onrender.com/api/app/version';

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      print("✅ App Version Check Successful:");
      print("Version: ${data['version']}");
      print("Changelog: ${data['changelog']}");
      print("Mandatory Update: ${data['mandatory']}");
      print("Platform: ${data['platform']}");

      const currentVersion = "1.0.3";
      if (data['version'] != currentVersion) {
        print("⚠️ New version available: ${data['version']}");
      } else {
        print("✅ App is up-to-date.");
      }
    } else {
      print(
        "❌ Failed to fetch app version. Status code: ${response.statusCode}",
      );
    }
  } catch (e) {
    print("❌ Error checking app version: $e");
  }
}

Future<void> trackInstallIfFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  final hasInstalled = prefs.getBool('hasInstalled') ?? false;

  if (!hasInstalled) {
    final platform = Platform.isAndroid ? "Android" : "iOS";
    await AnalyticsService.trackEvent('app_install', {'platform': platform});
    await prefs.setBool('hasInstalled', true);
    print("✅ Installation tracked.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FavoritesProvider())],
      child: MaterialApp(
        title: 'Movie App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        home: const HomePage(), // Directly go to HomePage
      ),
    );
  }
}
