import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

class TmdbApiService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  /// Fetches the YouTube video key for the movie's trailer or teaser.
  static Future<String?> fetchMovieVideoUrl(int movieId) async {
    final url = Uri.parse(
        '$_baseUrl/movie/$movieId/videos?api_key=${Config.omdbApiKey}&language=en-US');

    int retries = 3;
    while (retries > 0) {
      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List<dynamic>;
          // Find a YouTube trailer or teaser video
          final video = results.firstWhere(
            (video) =>
                video['site'] == 'YouTube' &&
                (video['type'] == 'Trailer' || video['type'] == 'Teaser'),
            orElse: () => null,
          );
          if (video != null) {
            final key = video['key'];
            return 'https://www.youtube.com/watch?v=$key';
          }
          return null;
        } else {
          return null;
        }
      } catch (e) {
        retries--;
        if (retries == 0) {
          return null;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  /// Fetches movies by category.
  static Future<List<dynamic>> fetchMoviesByCategory(String category) async {
    final url = Uri.parse(
        '$_baseUrl/movie/${_mapCategoryToEndpoint(category)}?api_key=${Config.omdbApiKey}&language=en-US&page=1');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] as List<dynamic>;
    } else {
      throw Exception('Failed to load movies for category $category');
    }
  }

  /// Fetches series by category.
  static Future<List<dynamic>> fetchSeriesByCategory(String category) async {
    final url = Uri.parse(
        '$_baseUrl/tv/${_mapCategoryToEndpoint(category)}?api_key=${Config.omdbApiKey}&language=en-US&page=1');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] as List<dynamic>;
    } else {
      throw Exception('Failed to load series for category $category');
    }
  }

  static String _mapCategoryToEndpoint(String category) {
    switch (category.toLowerCase()) {
      case 'trending':
        return 'popular';
      case 'recent':
        return 'now_playing';
      case 'action':
        return 'popular'; // TMDb does not have direct category, use popular as fallback
      case 'comedy':
        return 'popular';
      case 'drama':
        return 'popular';
      default:
        return 'popular';
    }
  }
}
