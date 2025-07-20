import 'package:flutter/material.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child:
              movie.posterPath.isNotEmpty
                  ? Image.network(
                    movie.posterPath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                  : Container(
                    color: Colors.grey,
                    width: double.infinity,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                      ),
                    ),
                  ),
        ),
        const SizedBox(height: 4),
        Text(
          movie.title,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
