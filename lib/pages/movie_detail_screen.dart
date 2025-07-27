import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // ✅ Added
import 'package:my_new_movie_app/pages/movie_player_widget.dart';
import '../models/movie.dart';
import '../services/movie_fetch_service.dart';
import '../services/analytics_service.dart';
import '../widgets/movie_card.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final List<Movie>? relatedMovies;

  const MovieDetailScreen({super.key, required this.movie, this.relatedMovies});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<List<Movie>> _otherSeriesFuture;

  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();

    // ✅ Keep screen awake
    WakelockPlus.enable();

    if (widget.movie.type == 'episode') {
      _otherSeriesFuture = MovieFetchService.fetchSeriesByCategoryAndRegion(
        'All',
        'All',
      );
    }

    // Track movie viewed for analytics
    AnalyticsService.trackEvent('movie_viewed', {
      'movieId': widget.movie.id,
      'movieTitle': widget.movie.title,
    });
  }

  @override
  void dispose() {
    // ✅ Allow screen to sleep again
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEpisode = widget.movie.type == 'episode';
    final relatedMovies =
        widget.relatedMovies?.where((m) => m.id != widget.movie.id).toList() ??
        [];
    final relatedEpisodes =
        isEpisode
            ? relatedMovies.where((m) => m.type == 'episode').toList()
            : [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                await AnalyticsService.trackEvent('movie_play', {
                  'movieId': widget.movie.id,
                  'movieTitle': widget.movie.title,
                });

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => MoviePlayerWidget(
                          videoSources: widget.movie.videoSources,
                        ),
                  ),
                );
              },
              child: MoviePlayerWidget(videoSources: widget.movie.videoSources),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              widget.movie.overview,
                              maxLines: _isDescriptionExpanded ? null : 3,
                              overflow:
                                  _isDescriptionExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!_isDescriptionExpanded)
                            Text(
                              "Read more",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                "⭐ ${widget.movie.voteAverage.toStringAsFixed(1)}",
                                style: const TextStyle(color: Colors.amber),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "Released: ${widget.movie.releaseDate}",
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (relatedMovies.isNotEmpty && !isEpisode) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          "More Like This",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: relatedMovies.length,
                        itemBuilder: (context, index) {
                          final related = relatedMovies[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => MovieDetailScreen(
                                        movie: related,
                                        relatedMovies: widget.relatedMovies,
                                      ),
                                ),
                              );
                            },
                            child: MovieCard(movie: related),
                          );
                        },
                      ),
                    ],

                    if (isEpisode && relatedEpisodes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          "Other Episodes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: relatedEpisodes.length,
                          itemBuilder: (context, index) {
                            final episode = relatedEpisodes[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => MovieDetailScreen(
                                          movie: episode,
                                          relatedMovies: widget.relatedMovies,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.all(8),
                                child: MovieCard(movie: episode),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    if (isEpisode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              "Other Series",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FutureBuilder<List<Movie>>(
                            future: _otherSeriesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    "Failed to load other series.",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                );
                              }

                              final otherSeries =
                                  snapshot.data!
                                      .where((s) => s.id != widget.movie.id)
                                      .toList();

                              return SizedBox(
                                height: 190,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: otherSeries.length,
                                  itemBuilder: (context, index) {
                                    final series = otherSeries[index];
                                    return GestureDetector(
                                      onTap: () {
                                        _showEpisodesBottomSheet(
                                          context,
                                          series,
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.all(8),
                                        child: MovieCard(movie: series),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEpisodesBottomSheet(BuildContext context, Movie series) async {
    final episodes = await MovieFetchService.fetchEpisodesBySeriesId(series.id);

    if (!context.mounted) return;

    if (episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No episodes found for ${series.title}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
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
                separatorBuilder: (_, __) => Divider(color: Colors.grey[700]),
                itemBuilder: (ctx, index) {
                  final episode = episodes[index];
                  return ListTile(
                    title: Text(
                      episode.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushReplacement(
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
      },
    );
  }
}
