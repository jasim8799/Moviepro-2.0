import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsService {
  static const String baseUrl = 'https://api-15hv.onrender.com/api/analytics';

  static Future<void> trackEvent(
    String eventName,
    Map<String, dynamic> details,
  ) async {
    final url = Uri.parse('$baseUrl/track');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event': eventName,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        print(
          'Analytics tracking error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Analytics tracking exception: $e');
    }
  }
}
