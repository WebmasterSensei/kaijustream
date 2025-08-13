import 'package:KaijuStream/src/widgets/anime_search.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class AnimeDetailsPage extends StatefulWidget {
  const AnimeDetailsPage({super.key});

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isVideoInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Anime anime = ModalRoute.of(context)!.settings.arguments as Anime;

    if (anime.videoUrl != null && anime.videoUrl!.isNotEmpty) {
      _initializeVideo(anime.videoUrl!);
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      setState(() => _isVideoInitialized = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
      if (mounted) setState(() => _isVideoInitialized = true);
    });
  }

  Future<void> _openYouTubeVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _modernCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildShimmer({double height = 200}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(Anime anime) {
    if (anime.videoUrl != null &&
        (anime.videoUrl!.contains('youtube.com') ||
            anime.videoUrl!.contains('youtu.be'))) {
      return GestureDetector(
        onTap: () => _openYouTubeVideo(anime.videoUrl!),
        child: _modernCard(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://img.youtube.com/vi/${_extractYouTubeVideoId(anime.videoUrl!)}/maxresdefault.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _buildShimmer();
                  },
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.red.shade400,
                    size: 72,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _modernCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _isVideoInitialized) {
              return AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              );
            }
            return _buildShimmer();
          },
        ),
      ),
    );
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([^&\n?#]+)',
    );
    return regExp.firstMatch(url)?.group(1);
  }

  Widget _buildInfoItem(IconData icon, String label, String value,
      {Color? iconColor}) {
    return _modernCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Anime anime = ModalRoute.of(context)!.settings.arguments as Anime;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(anime.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Hero(
                tag: anime.imageUrl,
                child: Image.network(
                  anime.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _buildShimmer(height: 240);
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (anime.videoUrl?.isNotEmpty ?? false) ...[
                  _buildVideoPlayer(anime),
                  const SizedBox(height: 24),
                ],
                Text('Information',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildInfoItem(Icons.star, 'Score',
                    anime.score?.toString() ?? 'N/A',
                    iconColor: Colors.amber),
                const SizedBox(height: 8),
                _buildInfoItem(Icons.tv, 'Episodes',
                    anime.episodes?.toString() ?? 'N/A',
                    iconColor: Colors.blue),
                const SizedBox(height: 8),
                _buildInfoItem(Icons.info_outline, 'Status',
                    anime.status ?? 'Unknown',
                    iconColor: Colors.green),
                const SizedBox(height: 24),
                if (anime.synopsis?.isNotEmpty ?? false) ...[
                  Text('Synopsis',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _modernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(anime.synopsis!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (anime.genres.isNotEmpty) ...[
                  Text('Genres',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: anime.genres
                        .map((g) => Chip(
                              label: Text(g),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              labelStyle: const TextStyle(color: Colors.white),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
