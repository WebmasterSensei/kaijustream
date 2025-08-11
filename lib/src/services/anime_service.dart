// lib/services/anime_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mini/models/anime_model.dart';

class AnimeService {
  
  static const String baseUrl = 'https://api.jikan.moe/v4';

  Future<List<Anime>> searchAnime(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/anime?q=$query'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> animeList = data['data'];
      return animeList.map((json) => Anime.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load anime');
    }
  }
}