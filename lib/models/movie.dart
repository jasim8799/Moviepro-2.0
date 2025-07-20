class VideoSource {
  final String url;
  final String quality;
  final String language;

  VideoSource({
    required this.url,
    required this.quality,
    required this.language,
  });

  factory VideoSource.fromJson(Map<String, dynamic> json) => VideoSource(
    url: json['url'] ?? '',
    quality: json['quality'] ?? 'Unknown',
    language: json['language'] ?? 'Unknown',
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'quality': quality,
    'language': language,
  };
}

class Movie {
  final String id;
  final String title;
  final String overview;
  final String category;
  final String region;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;
  final List<VideoSource> videoSources;
  final String type;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.category,
    required this.region,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.videoSources,
    required this.type,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    String id = '';
    if (json['_id'] != null) {
      if (json['_id'] is String) {
        id = json['_id'];
      } else {
        id = json['_id'].toString();
      }
    }

    return Movie(
      id: id,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      category: json['category'] ?? '',
      region: json['region'] ?? 'All',
      posterPath: json['posterPath'] ?? '',
      releaseDate: json['releaseDate'] ?? '',
      voteAverage:
          (json['voteAverage'] != null)
              ? double.tryParse(json['voteAverage'].toString()) ?? 0.0
              : 0.0,
      videoSources:
          ((json['videoLinks'] ?? json['videoSources']) as List<dynamic>?)
              ?.map((item) => VideoSource.fromJson(item))
              .toList() ??
          [],
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'overview': overview,
    'category': category,
    'region': region,
    'posterPath': posterPath,
    'releaseDate': releaseDate,
    'voteAverage': voteAverage,
    'videoSources': videoSources.map((vs) => vs.toJson()).toList(),
    'type': type,
  };

  String get fullPosterPath {
    const baseUrl = 'https://api-15hv.onrender.com';
    if (posterPath.isNotEmpty && posterPath != 'N/A') {
      if (posterPath.startsWith('http')) {
        return posterPath;
      } else {
        if (posterPath.startsWith('/')) {
          return baseUrl + posterPath;
        } else {
          return '$baseUrl/$posterPath';
        }
      }
    }
    return 'assets/images/placeholder.jpg';
  }
}
