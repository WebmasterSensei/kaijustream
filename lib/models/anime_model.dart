// lib/models/anime.dart
class Anime {
  final int malId;
  final String title;
  final String imageUrl;
  final double score;
  final int episodes;
  final String status;
  final String synopsis;
  final List<String> genres;

  Anime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.episodes,
    required this.status,
    required this.synopsis,
    required this.genres,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'],
      title: json['title'] ?? 'No title',
      imageUrl: json['images']['jpg']['image_url'] ?? '',
      score: json['score']?.toDouble() ?? 0.0,
      episodes: json['episodes'] ?? 0,
      status: json['status'] ?? 'Unknown',
      synopsis: json['synopsis'] ?? 'Unknown',
      genres: json['genres'] ?? 'Unknown',
    );
  }
}
