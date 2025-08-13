import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:KaijuStream/models/anime_model.dart';

class AnimeProvider with ChangeNotifier {
  List<Anime> _animeList = [];
  List<Anime> _topAnime = [];
  bool _isLoading = false;
  String _error = '';

  List<Anime> get animeList => _animeList;
  List<Anime> get topAnime => _topAnime;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchTopAnime() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/top/anime?p='),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _topAnime =
            (data['data'] as List)
                .map((anime) => Anime.fromJson(anime))
                .toList();
        _error = '';
      } else {
        _error = 'Failed to load top anime';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchAnime(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _animeList =
            (data['data'] as List)
                .map((anime) => Anime.fromJson(anime))
                .toList();
        _error = '';
      } else {
        _error = 'Failed to search anime';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
