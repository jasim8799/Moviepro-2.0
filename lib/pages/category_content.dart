import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../pages/movie_detail_screen.dart';
import '../widgets/movie_card.dart';

class CategoryContent extends StatelessWidget {
  final String categoryName;
  final Future<List<Movie>> Function() fetchMovies;

  const CategoryContent({
    super.key,
    required this.categoryName,
    required this.fetchMovies,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Movie>>(
      future: fetchMovies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: MovieCard(movie: movie),
              );
            },
          );
        }
      },
    );
  }
}
