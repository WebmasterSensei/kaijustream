import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Anime {
  final String title;
  final String imageUrl;
  final double? score;
  final int? rank;
  final String? synopsis;

  Anime({
    required this.title,
    required this.imageUrl,
    this.score,
    this.rank,
    this.synopsis,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      title: json['title'] ?? 'No Title',
      imageUrl:
          json['images']?['jpg']?['large_image_url'] ??
          json['images']?['jpg']?['image_url'] ??
          '',
      score: json['score']?.toDouble(),
      rank: json['rank'],
      synopsis: json['synopsis'],
    );
  }
}

class AnimeService {
  static const String baseUrl = 'https://api.jikan.moe/v4';

  static Future<List<Anime>> fetchTopAnime({int limit = 10}) async {
    try {
      final url = Uri.parse('$baseUrl/top/anime?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List animeList = data['data'] ?? [];
        return animeList.map((anime) => Anime.fromJson(anime)).toList();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch anime: $e');
    }
  }

  static Future<List<Anime>> fetchSeasonalAnime({int limit = 5}) async {
    try {
      final url = Uri.parse('$baseUrl/seasons/now?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List animeList = data['data'] ?? [];
        return animeList.map((anime) => Anime.fromJson(anime)).toList();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch seasonal anime: $e');
    }
  }
}

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late Future<List<Anime>> _futureSeasonalAnime;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureSeasonalAnime = AnimeService.fetchSeasonalAnime();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Anime>>(
      future: _futureSeasonalAnime,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCarousel();
        } else if (snapshot.hasError) {
          return _buildErrorCarousel();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyCarousel();
        }

        return _buildAnimeCarousel(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingCarousel() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading featured anime...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCarousel() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('Failed to load featured content'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _futureSeasonalAnime = AnimeService.fetchSeasonalAnime();
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCarousel() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No featured content available')),
      ),
    );
  }

  Widget _buildAnimeCarousel(List<Anime> animeList) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: animeList.length,
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final anime = animeList[index];
            return _buildCarouselItem(anime, index);
          },
        ),
        const SizedBox(height: 12),
        _buildIndicators(animeList.length),
      ],
    );
  }

  Widget _buildCarouselItem(Anime anime, int index) {
    final promoTexts = [
      'Now Trending',
      'Must Watch',
      'Popular This Season',
      'Highly Rated',
      'Editor\'s Pick',
    ];

    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Anime image
                anime.imageUrl.isNotEmpty
                    ? Image.network(
                      anime.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.movie_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    )
                    : Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                // Gradient overlays
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Top badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(index),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      promoTexts[index % promoTexts.length],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Score badge
                if (anime.score != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            anime.score!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Anime title and info
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (anime.synopsis != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          anime.synopsis!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            shadows: const [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicators(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: _currentIndex == index ? 20 : 6,
          decoration: BoxDecoration(
            color:
                _currentIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}
