import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_new_movie_app/screens/search/search_page.dart';
import '../models/movie.dart';
import '../services/movie_fetch_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/modern_ad_banner.dart';
import '../pages/movie_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class BollywoodPage extends StatefulWidget {
  const BollywoodPage({super.key});

  @override
  State<BollywoodPage> createState() => _BollywoodPageState();
}

class _BollywoodPageState extends State<BollywoodPage> {
  final List<Movie> _movies = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOffline = false;
  bool _isServerError = false;
  int _currentPage = 1;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMovies();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _hasMore &&
          !_isOffline &&
          !_isServerError) {
        _loadMoreMovies();
      }
    });
  }

  Future<void> _fetchMovies() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
        _isLoading = false;
      });
      return;
    }

    int retries = 0;
    const maxRetries = 2;
    bool success = false;

    while (!success && retries <= maxRetries) {
      try {
        final movies = await MovieFetchService.fetchMoviesByCategoryAndRegion(
          'All',
          'Bollywood',
          page: _currentPage,
          limit: _limit,
        );

        final serverError = MovieFetchService.hadServerError();

        if (!serverError) {
          setState(() {
            _movies.addAll(movies);
            _hasMore = movies.length == _limit;
            _isServerError = false;
            _isOffline = false;
            _isLoading = false;
            _currentPage++;
          });
          success = true;
        } else {
          retries++;
        }
      } catch (_) {
        retries++;
      }
    }

    if (!success) {
      setState(() {
        _isServerError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMovies() async {
    setState(() => _isLoadingMore = true);

    try {
      final moreMovies = await MovieFetchService.fetchMoviesByCategoryAndRegion(
        'All',
        'Bollywood',
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _movies.addAll(moreMovies);
        _hasMore = moreMovies.isNotEmpty;
        _isLoadingMore = false;
        _currentPage++;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _movies.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      _isServerError = false;
      _isOffline = false;
    });
    await _fetchMovies();
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder:
          (_, __) => Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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
              child:
                  _isLoading
                      ? _buildShimmer()
                      : _isOffline
                      ? const Center(
                        child: Text(
                          '🔴 You are offline. Please check your internet connection.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : _isServerError
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🔴 Failed to load movies. Server error occurred.',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _fetchMovies,
                              child: const Text(
                                "Retry",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : _movies.isEmpty
                      ? const Center(
                        child: Text(
                          'No Bollywood movies found.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: Colors.redAccent,
                        backgroundColor: Colors.black,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.6,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _movies.length + (_isLoadingMore ? 3 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _movies.length) {
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[800]!,
                                highlightColor: Colors.grey[600]!,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }

                            final movie = _movies[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => MovieDetailScreen(
                                          movie: movie,
                                          relatedMovies: _movies,
                                        ),
                                  ),
                                );
                              },
                              child: MovieCard(movie: movie),
                            );
                          },
                        ),
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
