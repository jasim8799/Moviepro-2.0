import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class MovieFetchService {
  /// Fetches episodes for a specific series ID from the backend API
  static Future<List<Movie>> fetchEpisodesBySeriesId(String seriesId) async {
    final String url =
        'https://api-15hv.onrender.com/api/episodes?seriesId=$seriesId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Movie>((item) {
          return Movie(
            id: item['_id'] ?? '',
            title: item['title'] ?? '',
            overview: item['overview'] ?? '',
            category: item['category'] ?? '',
            region: item['region'] ?? 'All',
            posterPath: item['posterPath'] ?? '',
            releaseDate: item['releaseDate'] ?? '',
            voteAverage:
                double.tryParse(item['voteAverage']?.toString() ?? '') ?? 0.0,
            videoSources:
                (item['videoSources'] as List<dynamic>?)
                    ?.map((source) => VideoSource.fromJson(source))
                    .toList() ??
                [],
            type: item['type'] ?? 'episode',
          );
        }).toList();
      } else {
        print(
          'fetchEpisodesBySeriesId: Failed - Status code ${response.statusCode}',
        );
        return [];
      }
    } catch (e, stacktrace) {
      print('fetchEpisodesBySeriesId: Error - $e');
      print('Stacktrace: $stacktrace');
      return [];
    }
  }
}
