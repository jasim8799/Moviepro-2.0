import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_new_movie_app/screens/search/search_page.dart';
import '../models/movie.dart';
import '../services/movie_fetch_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/modern_ad_banner.dart';
import '../pages/movie_detail_screen.dart';

class BollywoodPage extends StatefulWidget {
  const BollywoodPage({super.key});

  @override
  State<BollywoodPage> createState() => _BollywoodPageState();
}

class _BollywoodPageState extends State<BollywoodPage> {
  late Future<MovieFetchResult> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _fetchMoviesWithStatus();
  }

  Future<MovieFetchResult> _fetchMoviesWithStatus() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return MovieFetchResult(
        movies: [],
        isOffline: true,
        isServerError: false,
      );
    }

    try {
      final movies = await MovieFetchService.fetchMoviesByCategoryAndRegion(
        'All',
        'Bollywood',
      );

      // ✅ Use flag to detect if API failed
      final serverError = MovieFetchService.hadServerError();

      return MovieFetchResult(
        movies: movies,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<MovieFetchResult>(
                future: _moviesFuture,
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
                          '🔴 Failed to load movies. Server error occurred.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (result.movies.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Bollywood movies found.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: result.movies.length,
                        itemBuilder: (context, index) {
                          final movie = result.movies[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => MovieDetailScreen(
                                        movie: movie,
                                        relatedMovies: result.movies,
                                      ),
                                ),
                              );
                            },
                            child: MovieCard(movie: movie),
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
