import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/favorites_service.dart';


class FavoritesProvider extends ChangeNotifier {
  Set<String> _favoriteIds = {};
  final List<Movie> _allMovies = [];
  List<Movie> _favoriteMovies = [];

  Set<String> get favoriteIds => _favoriteIds;
  List<Movie> get favoriteMovies => _favoriteMovies;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final ids = await FavoritesService.loadFavoriteIds();
    _favoriteIds = ids.toSet();
    _updateFavoriteMovies();
    notifyListeners();
  }

  void setFavoriteMovies(List<Movie> movies) {
    // Merge new movies into _allMovies without duplicates
    for (var movie in movies) {
      if (!_allMovies.any((m) => m.id == movie.id)) {
        _allMovies.add(movie);
      }
    }
    _updateFavoriteMovies();
    notifyListeners();
  }

  void _updateFavoriteMovies() {
    _favoriteMovies =
        _allMovies.where((m) => _favoriteIds.contains(m.id)).toList();
  }

  Future<void> toggleFavorite(Movie movie) async {
    if (_favoriteIds.contains(movie.id)) {
      _favoriteIds.remove(movie.id);
      _favoriteMovies.removeWhere((m) => m.id == movie.id);
    } else {
      _favoriteIds.add(movie.id);
      _favoriteMovies.add(movie);
      if (!_allMovies.any((m) => m.id == movie.id)) {
        _allMovies.add(movie);
      }
    }
    await FavoritesService.saveFavoriteIds(_favoriteIds.toList());
    notifyListeners();
  }

  Future<void> removeFavorite(Movie movie) async {
    if (_favoriteIds.contains(movie.id)) {
      _favoriteIds.remove(movie.id);
      _favoriteMovies.removeWhere((m) => m.id == movie.id);
      await FavoritesService.saveFavoriteIds(_favoriteIds.toList());
      notifyListeners();
    }
  }
}
