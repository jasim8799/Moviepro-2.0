import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class MovieFetchService {
  static const String baseUrl =
      'https://proxy-server-6hu9.onrender.com/proxy/api';
  static const Map<String, String> headers = {
    'Authorization':
        'Bearer dfghjk45678vbnm5678ixcvbnjmkr5t6y7u8icvbnjm56y7uvbhnjmkr5678vbhnj',
  };

  static String proxiedVideoUrl(String uid) {
    return 'https://proxy-server-6hu9.onrender.com/proxy/video/$uid/manifest/video.m3u8';
  }

  static bool lastApiHadServerError = false;

  static Future<List<Movie>> fetchByCategory(
    String category,
    bool isSeries,
  ) async {
    final String endpoint =
        category.isEmpty
            ? (isSeries ? '$baseUrl/series' : '$baseUrl/movies')
            : (isSeries
                ? '$baseUrl/series/category/$category'
                : '$baseUrl/movies/category/$category');

    print('MovieFetchService: Fetching from endpoint: $endpoint');
    lastApiHadServerError = false;

    try {
      final response = await http.get(Uri.parse(endpoint), headers: headers);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        if (category.isEmpty) {
          final Map<String, dynamic> json = jsonDecode(response.body);
          final List<dynamic> items =
              isSeries ? (json['series'] ?? []) : (json['movies'] ?? []);
          return items.map<Movie>((item) => Movie.fromJson(item)).toList();
        } else {
          final List<dynamic> json = jsonDecode(response.body);
          return json.map<Movie>((item) => Movie.fromJson(item)).toList();
        }
      } else {
        print('MovieFetchService: Failed with status ${response.statusCode}');
        lastApiHadServerError = true;
        return [];
      }
    } catch (e, stacktrace) {
      print('MovieFetchService: Error fetching category: $e');
      print('Stacktrace: $stacktrace');
      lastApiHadServerError = true;
      return [];
    }
  }

  static Future<void> incrementViews(String movieId) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId/increment-views');

    try {
      final response = await http.put(uri, headers: headers);
      if (response.statusCode != 200) {
        print('Failed to increment views for movieId: $movieId');
      }
    } catch (e) {
      print('Error incrementing views for movieId: $movieId - $e');
    }
  }

  static Future<List<Movie>> fetchMoviesByCategoryAndRegion(
    String category,
    String region, {
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> queryParams = {
      'type': 'movie',
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category.toLowerCase();
    }
    if (region.isNotEmpty && region.toLowerCase() != 'all') {
      queryParams['region'] = region.toLowerCase();
    }

    final uri = Uri.parse(
      '$baseUrl/movies',
    ).replace(queryParameters: queryParams);
    print('MovieFetchService: Fetch movies with URL: $uri');
    lastApiHadServerError = false;

    try {
      final response = await http.get(uri, headers: headers);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['movies'] ?? [];
        return data.map<Movie>((item) => Movie.fromJson(item)).toList();
      } else {
        print('Fetch failed with status ${response.statusCode}');
        lastApiHadServerError = true;
        return [];
      }
    } catch (e, stacktrace) {
      print('Error fetching movies by category & region: $e');
      print('Stacktrace: $stacktrace');
      lastApiHadServerError = true;
      return [];
    }
  }

  // ✅ Updated with pagination support
  static Future<List<Movie>> fetchSeriesByCategoryAndRegion(
    String category,
    String region, {
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> queryParams = {
      'type': 'series',
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category.toLowerCase();
    }
    if (region.isNotEmpty && region.toLowerCase() != 'all') {
      queryParams['region'] = region.toLowerCase();
    }

    final uri = Uri.parse(
      '$baseUrl/series',
    ).replace(queryParameters: queryParams);
    print('MovieFetchService: Fetch series with URL: $uri');
    lastApiHadServerError = false;

    try {
      final response = await http.get(uri, headers: headers);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['series'] ?? [];
        return data.map<Movie>((item) => Movie.fromJson(item)).toList();
      } else {
        print('Fetch failed with status ${response.statusCode}');
        lastApiHadServerError = true;
        return [];
      }
    } catch (e, stacktrace) {
      print('Error fetching series by category & region: $e');
      print('Stacktrace: $stacktrace');
      lastApiHadServerError = true;
      return [];
    }
  }

  static Future<List<Movie>> fetchEpisodesBySeriesId(String seriesId) async {
    final String url =
        '$baseUrl/episodes?seriesId=${Uri.encodeComponent(seriesId)}';
    print('MovieFetchService: Fetch episodes with URL: $url');
    lastApiHadServerError = false;

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Movie>((item) {
          final movie = Movie.fromJson(item);
          return Movie(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            category: movie.category,
            region: movie.region,
            posterPath: movie.posterPath,
            releaseDate: movie.releaseDate,
            voteAverage: movie.voteAverage,
            videoSources: movie.videoSources,
            type: 'episode',
          );
        }).toList();
      } else {
        print('Failed to fetch episodes - status ${response.statusCode}');
        lastApiHadServerError = true;
        return [];
      }
    } catch (e, stacktrace) {
      print('Error fetching episodes: $e');
      print('Stacktrace: $stacktrace');
      lastApiHadServerError = true;
      return [];
    }
  }

  static Future<List<Movie>> searchMoviesByTitle(String title) async {
    final uri = Uri.parse(
      '$baseUrl/movies/search',
    ).replace(queryParameters: {'title': title});
    print('MovieFetchService: Search movies with URL: $uri');
    lastApiHadServerError = false;

    try {
      final response = await http.get(uri, headers: headers);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map<Movie>((item) => Movie.fromJson(item)).toList();
      } else {
        print('Search movies failed with status ${response.statusCode}');
        lastApiHadServerError = true;
        return [];
      }
    } catch (e, stacktrace) {
      print('Error searching movies: $e');
      print('Stacktrace: $stacktrace');
      lastApiHadServerError = true;
      return [];
    }
  }

  static Future<List<Movie>> searchSeriesByTitle(String title) async {
    final uri = Uri.parse(
      '$baseUrl/series/search',
    ).replace(queryParameters: {'title': title});
    print('MovieFetchService: Search series with URL: $uri');
    lastApiHadServerError = false;

    try {
      final response = await http.get(uri, headers: headers);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map<Movie>((item) => Movie.fromJson(item)).toList();
      } else {
        print('Search series failed with status ${response.statusCode}');
        lastApiHadServerError = true;
        return [];
      }
    } catch (e, stacktrace) {
      print('Error searching series: $e');
      print('Stacktrace: $stacktrace');
      lastApiHadServerError = true;
      return [];
    }
  }

  static bool hadServerError() {
    return lastApiHadServerError;
  }
}
