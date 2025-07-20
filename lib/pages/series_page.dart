import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/movie.dart';
import '../services/movie_fetch_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/modern_ad_banner.dart';
import '../screens/search/search_page.dart';
import '../pages/movie_detail_screen.dart';

class SeriesPage extends StatefulWidget {
  const SeriesPage({super.key});

  @override
  State<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  late Future<MovieFetchResult> _seriesFuture;

  @override
  void initState() {
    super.initState();
    _seriesFuture = _fetchSeriesWithStatus();
  }

  Future<MovieFetchResult> _fetchSeriesWithStatus() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return MovieFetchResult(
        movies: [],
        isOffline: true,
        isServerError: false,
      );
    }

    try {
      final series = await MovieFetchService.fetchSeriesByCategoryAndRegion(
        'All',
        'All',
      );

      final serverError = MovieFetchService.hadServerError();

      return MovieFetchResult(
        movies: series,
        isOffline: false,
        isServerError: serverError,
      );
    } catch (e) {
      return MovieFetchResult(
        movies: [],
        isOffline: false,
        isServerError: true,
      );
    }
  }

  void _showEpisodesBottomSheet(BuildContext context, Movie series) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<List<Movie>>(
          future: MovieFetchService.fetchEpisodesBySeriesId(series.id),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.redAccent),
              );
            } else if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Failed to load episodes.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No episodes found for this series.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else {
              final episodes = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    "Select Episode",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: episodes.length,
                      separatorBuilder:
                          (_, __) => Divider(color: Colors.grey[700]),
                      itemBuilder: (ctx, index) {
                        final episode = episodes[index];
                        return ListTile(
                          title: Text(
                            episode.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => MovieDetailScreen(
                                      movie: episode,
                                      relatedMovies: episodes,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<MovieFetchResult>(
                future: _seriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        '🔴 Unexpected error.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final result = snapshot.data!;
                    if (result.isOffline) {
                      return const Center(
                        child: Text(
                          '🔴 You are offline. Please check your internet connection.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (result.isServerError) {
                      return const Center(
                        child: Text(
                          '🔴 Failed to load series. Server error occurred.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (result.movies.isEmpty) {
                      return const Center(
                        child: Text(
                          'No series found.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      final seriesList = result.movies;
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: seriesList.length,
                        itemBuilder: (context, index) {
                          final series = seriesList[index];
                          return GestureDetector(
                            onTap:
                                () => _showEpisodesBottomSheet(context, series),
                            child: MovieCard(movie: series),
                          );
                        },
                      );
                    }
                  } else {
                    return const Center(
                      child: Text(
                        'Something went wrong.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                },
              ),
            ),
            const ModernAdBanner(),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          backgroundColor: Colors.yellow,
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
          },
          child: const Icon(Icons.search, color: Colors.black, size: 24),
        ),
      ),
    );
  }
}

class MovieFetchResult {
  final List<Movie> movies;
  final bool isOffline;
  final bool isServerError;

  MovieFetchResult({
    required this.movies,
    required this.isOffline,
    required this.isServerError,
  });
}
