import 'package:flutter/material.dart';
import 'package:my_new_movie_app/models/movie.dart';
import 'package:my_new_movie_app/pages/movie_detail_screen.dart';
import 'package:my_new_movie_app/services/movie_fetch_service.dart';
import 'package:my_new_movie_app/widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Future<List<Movie>>? _searchFuture;
  List<Movie> _lastLoadedMovies = [];

  final List<String> categories = ['Trending', 'Action', 'Comedy', 'Drama'];

  @override
  void initState() {
    super.initState();
    _searchByCategory('Action');
  }

  void _searchMovies(String query) {
    setState(() {
      _searchFuture = MovieFetchService.searchMoviesByTitle(query).then((
        movies,
      ) async {
        if (movies.isNotEmpty) {
          // ✅ Fetch related movies from Action category
          List<Movie> related =
              await MovieFetchService.fetchMoviesByCategoryAndRegion(
                'Action',
                'All',
              );
          // Remove the searched movie from related list
          related.removeWhere((m) => m.id == movies.first.id);
          _lastLoadedMovies = related;
        } else {
          _lastLoadedMovies = [];
        }
        return movies;
      });
    });
  }

  void _searchByCategory(String category) {
    setState(() {
      _searchFuture = MovieFetchService.fetchMoviesByCategoryAndRegion(
        category,
        'All',
      ).then((movies) {
        _lastLoadedMovies = movies;
        return movies;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Search movies...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _searchMovies,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 30),
                onPressed: () {
                  _searchMovies(_controller.text);
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          _searchByCategory(cat);
                        },
                        child: Text(cat),
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(
            child:
                _searchFuture == null
                    ? const Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    : FutureBuilder<List<Movie>>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No movies found.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        } else {
                          final movies = snapshot.data!;
                          return GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: movies.length,
                            itemBuilder: (context, index) {
                              final movie = movies[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => MovieDetailScreen(
                                            movie: movie,
                                            relatedMovies: _lastLoadedMovies,
                                          ),
                                    ),
                                  );
                                },
                                child: MovieCard(movie: movie),
                              );
                            },
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
