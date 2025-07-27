// Your imports stay the same
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/movie.dart';
import '../services/movie_fetch_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/modern_ad_banner.dart';
import '../screens/search/search_page.dart';
import '../pages/movie_detail_screen.dart';
import '../services/analytics_service.dart';
import 'package:shimmer/shimmer.dart';

class SeriesPage extends StatefulWidget {
  const SeriesPage({super.key});

  @override
  State<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Movie> _seriesList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOffline = false;
  bool _isServerError = false;
  int _currentPage = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackEvent("movie_viewed", {"page": "bollywood"});
    _fetchSeries();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _seriesList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      _isServerError = false;
      _isOffline = false;
    });
    await _fetchSeries();
  }

  Future<void> _fetchSeries({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;

    if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    int retries = 0;
    const maxRetries = 2;
    bool success = false;

    while (!success && retries <= maxRetries) {
      try {
        final newSeries =
            await MovieFetchService.fetchSeriesByCategoryAndRegion(
              'All',
              'All',
              page: _currentPage,
              limit: _limit,
            );
        final serverError = MovieFetchService.hadServerError();

        if (!serverError) {
          setState(() {
            _isServerError = false;
            _isOffline = false;
            if (newSeries.isEmpty) {
              _hasMore = false;
            } else {
              _seriesList.addAll(newSeries);
              _currentPage++;
            }
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
      });
    }

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchSeries(loadMore: true);
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
                          leading: Image.network(
                            series.fullPosterPath,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                          ),
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

  Widget _buildShimmerGrid() {
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
          (context, index) => Shimmer.fromColors(
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                      ? _buildShimmerGrid()
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
                              '🔴 Failed to load series. Server error occurred.',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => _fetchSeries(),
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
                      : _seriesList.isEmpty
                      ? const Center(
                        child: Text(
                          'No series found.',
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
                          itemCount:
                              _seriesList.length + (_isLoadingMore ? 3 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _seriesList.length) {
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

                            final series = _seriesList[index];
                            return GestureDetector(
                              onTap:
                                  () =>
                                      _showEpisodesBottomSheet(context, series),
                              child: MovieCard(movie: series),
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
