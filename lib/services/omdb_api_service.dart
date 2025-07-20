import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class OmdbApiService {
  static const String _baseUrl = 'http://www.omdbapi.com/';

  /// Fetches movie details by IMDb ID from OMDb API.
  static Future<Map<String, dynamic>?> fetchMovieDetailsByImdbId(
      String imdbId) async {
    final url = Uri.parse('$_baseUrl?i=$imdbId&apikey=${Config.omdbApiKey}');

    try {
      final response = await http.get(url);
      print(
          'fetchMovieDetailsByImdbId response status: ${response.statusCode}');
      print('fetchMovieDetailsByImdbId response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'True') {
          return data;
        } else {
          print(
              'fetchMovieDetailsByImdbId API response False: ${data['Error']}');
          return null;
        }
      } else {
        print('fetchMovieDetailsByImdbId HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('fetchMovieDetailsByImdbId exception: $e');
      return null;
    }
  }

  /// Searches movies by title from OMDb API.
  static Future<List<Map<String, dynamic>>> searchMoviesByTitle(
      String title) async {
    final url = Uri.parse('$_baseUrl?s=$title&apikey=${Config.omdbApiKey}');

    try {
      final response = await http.get(url);
      print('searchMoviesByTitle response status: ${response.statusCode}');
      print('searchMoviesByTitle response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'True' && data['Search'] != null) {
          return List<Map<String, dynamic>>.from(data['Search']);
        } else {
          print('searchMoviesByTitle API response False: ${data['Error']}');
          return [];
        }
      } else {
        print('searchMoviesByTitle HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('searchMoviesByTitle exception: $e');
      return [];
    }
  }
}
