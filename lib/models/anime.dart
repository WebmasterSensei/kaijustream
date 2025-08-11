class AnimeTypes {
  final int id;
  final String title;
  final String imageUrl;
  final double score;
  final int episodes;
  final String status;
  final String? synopsis;
  final List<String>? genres;
  final String? year;
  final String? type;
  final int? rank;
  final String? season;

  AnimeTypes({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.episodes,
    required this.status,
    this.synopsis,
    this.genres,
    this.year,
    this.type,
    this.rank,
    this.season,
  });
}
