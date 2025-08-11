import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Enhanced Anime model with additional fields
class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final double score;
  final int episodes;
  final String status;
  final String synopsis;
  final List<String> genres;
  final String? year;
  final String? type;
  final int? rank;
  final String? season;
  final String? videoUrl;

  Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.episodes,
    required this.status,
    required this.synopsis,
    required this.genres,
    this.year,
    this.type,
    this.rank,
    this.season,
    this.videoUrl,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['mal_id'] ?? 0,
      title: json['title'] ?? json['title_english'] ?? 'No title',
      imageUrl:
          json['images']?['jpg']?['image_url'] ??
          'https://via.placeholder.com/300x400',
      score: (json['score'] ?? 0.0).toDouble(),
      episodes: json['episodes'] ?? 0,
      status: _mapApiStatus(json['status']),
      synopsis:
          json['synopsis']?.replaceAll('\n', ' ') ?? 'No synopsis available',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((genre) => genre['name'].toString())
              .toList() ??
          [],
      year: json['year']?.toString() ?? 'Unknown',
      type: json['type']?.toString() ?? 'Unknown',
      rank: json['rank'],
      season: json['season'],
      videoUrl:
          json['trailer']?['url'] ??
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    );
  }

  static String _mapApiStatus(String? apiStatus) {
    if (apiStatus == null) return 'Unknown';

    switch (apiStatus.toLowerCase()) {
      case 'currently_airing':
        return 'Ongoing';
      case 'finished_airing':
        return 'Finished';
      case 'not_yet_aired':
        return 'Upcoming';
      default:
        return apiStatus;
    }
  }
}

// Enhanced Anime Search Page
class AnimeSearchPage extends StatefulWidget {
  const AnimeSearchPage({super.key});

  @override
  State<AnimeSearchPage> createState() => _AnimeSearchPageState();
}

class _AnimeSearchPageState extends State<AnimeSearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Anime> _animeList = [];
  List<String> _recentSearches = [];
  List<String> _popularSearches = [
    'Naruto',
    'Attack on Titan',
    'One Piece',
    'Demon Slayer',
    'My Hero Academia',
    'Jujutsu Kaisen',
    'Death Note',
    'Dragon Ball',
    'Fullmetal Alchemist',
    'Tokyo Ghoul',
  ];

  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  String _currentQuery = '';
  bool _isGridView = false;

  Timer? _debounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initAnimations();
    _setupScrollListener();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreResults();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // In real implementation, load from SharedPreferences
    setState(() {
      _recentSearches = ['One Piece', 'Naruto', 'Attack on Titan'];
    });
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });
    // In real implementation, save to SharedPreferences
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty && query != _currentQuery) {
        _searchAnime(query);
      }
    });
  }

  Future<void> _searchAnime([
    String? customQuery,
    bool resetPage = false,
  ]) async {
    final query = customQuery ?? _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _animeList = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }

    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _hasMorePages = true;
        _animeList = [];
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
      _currentQuery = query;
    });

    try {
      final results = await _fetchAnimeFromAPI(query, _currentPage);

      setState(() {
        if (resetPage) {
          _animeList = results;
        } else {
          _animeList.addAll(results);
        }
        _isLoading = false;
        _hasMorePages =
            results.length >= 25; // API typically returns 25 per page
      });

      _saveRecentSearch(query);
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch anime: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final results = await _fetchAnimeFromAPI(_currentQuery, _currentPage);
      setState(() {
        _animeList.addAll(results);
        _hasMorePages = results.length >= 25;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--; // Revert page increment on error
        _isLoadingMore = false;
      });
    }
  }

  Future<List<Anime>> _fetchAnimeFromAPI(String query, int page) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.jikan.moe/v4/anime?q=$query&page=$page&limit=25',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'] ?? [];

        return results.map((animeData) => Anime.fromJson(animeData)).toList();
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment.');
      } else {
        throw Exception('Failed to load anime: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _animeList = [];
      _hasSearched = false;
      _errorMessage = '';
      _currentQuery = '';
    });
    _fadeController.reset();
    _slideController.reset();
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchAnime(suggestion);
    _searchFocusNode.unfocus();
  }

  void _toggleViewMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          _buildSearchSection(colorScheme),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        'Search Anime',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: colorScheme.surfaceContainer,
      elevation: 0,
      actions: [
        if (_hasSearched && _animeList.isNotEmpty) ...[
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                key: ValueKey(_isGridView),
              ),
            ),
            onPressed: _toggleViewMode,
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ],
    );
  }

  Widget _buildSearchSection(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width > 600 ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildSearchBar(colorScheme),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isLargeScreen ? 800 : double.infinity,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _searchFocusNode.hasFocus
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _searchAnime(),
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                decoration: InputDecoration(
                  hintText: 'Search for anime titles, genres, or keywords...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: isLargeScreen ? 16 : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24 : 20,
                    vertical: isLargeScreen ? 20 : 16,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                    child: Icon(
                      Icons.search_rounded,
                      color: colorScheme.primary,
                      size: isLargeScreen ? 24 : 20,
                    ),
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: _clearSearch,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          )
                          : null,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(right: isLargeScreen ? 12 : 8),
                child: Material(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _searchAnime(),
                    child: Container(
                      padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: isLargeScreen ? 24 : 20,
                                height: isLargeScreen ? 24 : 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                              : Icon(
                                Icons.search_rounded,
                                color: colorScheme.onPrimary,
                                size: isLargeScreen ? 24 : 20,
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasSearched) {
      return _buildSearchSuggestions();
    } else if (_isLoading && _animeList.isEmpty) {
      return _buildLoadingState();
    } else if (_errorMessage.isNotEmpty && _animeList.isEmpty) {
      return _buildErrorState();
    } else if (_animeList.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildSearchResults();
    }
  }

  Widget _buildSearchSuggestions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 800 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_recentSearches.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Recent Searches',
                      Icons.history_rounded,
                      isLargeScreen,
                    ),
                    SizedBox(height: isLargeScreen ? 16 : 12),
                    _buildSearchChips(
                      _recentSearches,
                      showClear: true,
                      isLargeScreen: isLargeScreen,
                    ),
                    SizedBox(height: isLargeScreen ? 32 : 24),
                  ],
                  _buildSectionHeader(
                    'Popular Searches',
                    Icons.trending_up_rounded,
                    isLargeScreen,
                  ),
                  SizedBox(height: isLargeScreen ? 16 : 12),
                  _buildSearchChips(
                    _popularSearches,
                    isLargeScreen: isLargeScreen,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isLargeScreen) {
    return Row(
      children: [
        Icon(
          icon,
          size: isLargeScreen ? 24 : 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: isLargeScreen ? 12 : 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isLargeScreen ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchChips(
    List<String> searches, {
    bool showClear = false,
    required bool isLargeScreen,
  }) {
    return Wrap(
      spacing: isLargeScreen ? 12 : 8,
      runSpacing: isLargeScreen ? 12 : 8,
      children:
          searches.map((search) {
            return Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _selectSuggestion(search),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 20 : 16,
                    vertical: isLargeScreen ? 12 : 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    search,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 16 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Searching for anime...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we find the best results',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _searchAnime(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No anime found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Try searching for a different anime title or check your spelling',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildResultsHeader(),
            Expanded(
              child: _buildGridResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_animeList.length} results for "$_currentQuery"',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
                fontSize: isLargeScreen ? 16 : 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              // Show filter options
              _showFilterBottomSheet();
            },
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
    );
  }

  Widget _buildListResults() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _animeList.length + (_hasMorePages ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        if (index == _animeList.length) {
          return _buildLoadMoreIndicator();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: EnhancedAnimeCard(
            anime: _animeList[index],
            onTap: () => _navigateToDetails(_animeList[index]),
          ),
        );
      },
    );
  }

  Widget _buildGridResults() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 180,
          ),
          itemCount: _animeList.length + (_hasMorePages ? crossAxisCount : 0),
          itemBuilder: (context, index) {
            if (index >= _animeList.length) {
              return _buildLoadMoreIndicator();
            }

            return EnhancedAnimeCard(
              anime: _animeList[index],
              onTap: () => _navigateToDetails(_animeList[index]),
              isCompact: true,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMorePages) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child:
            _isLoadingMore
                ? const CircularProgressIndicator()
                : const Text('Loading more...'),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter & Sort',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.sort_rounded),
                  title: const Text('Sort by Score'),
                  onTap: () {
                    Navigator.pop(context);
                    _sortAnimeList('score');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range_rounded),
                  title: const Text('Sort by Year'),
                  onTap: () {
                    Navigator.pop(context);
                    _sortAnimeList('year');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.abc_rounded),
                  title: const Text('Sort by Title'),
                  onTap: () {
                    Navigator.pop(context);
                    _sortAnimeList('title');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _sortAnimeList(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'score':
          _animeList.sort((a, b) => b.score.compareTo(a.score));
          break;
        case 'year':
          _animeList.sort((a, b) => (b.year ?? '0').compareTo(a.year ?? '0'));
          break;
        case 'title':
          _animeList.sort((a, b) => a.title.compareTo(b.title));
          break;
      }
    });
  }

  void _navigateToDetails(Anime anime) {
    Navigator.pushNamed(context, '/anime-details', arguments: anime);
  }
}

// Enhanced Anime Card (same as previous implementation)
class EnhancedAnimeCard extends StatelessWidget {
  final Anime anime;
  final VoidCallback? onTap;
  final bool isCompact;

  const EnhancedAnimeCard({
    super.key,
    required this.anime,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    final cardHeight = _getCardHeight(screenWidth);
    final imageWidth = _getImageWidth(screenWidth);
    final imageHeight = cardHeight - 90;

    return Card(
      elevation: 6,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: cardHeight,
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPosterImage(
                  context,
                  colorScheme,
                  imageWidth,
                  imageHeight,
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: _buildContent(
                    context,
                    theme,
                    colorScheme,
                    isTablet,
                    isDesktop,
                  ),
                ),
                if (!isCompact)
                  _buildActionButton(context, colorScheme, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getCardHeight(double screenWidth) {
    if (isCompact) return 110;
    if (screenWidth > 1200) return 200;
    if (screenWidth > 600) return 180;
    return 190;
  }

  double _getImageWidth(double screenWidth) {
    if (isCompact) return 80;
    if (screenWidth > 1200) return 140;
    if (screenWidth > 600) return 120;
    return 100;
  }

  Widget _buildPosterImage(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
    double height,
  ) {
    return Hero(
      tag: 'anime_${anime.id}_image',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              anime.imageUrl.isNotEmpty
                  ? Image.network(
                    anime.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImagePlaceholder(
                        colorScheme,
                        isLoading: true,
                        progress:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder(
                        colorScheme,
                        hasError: true,
                      );
                    },
                  )
                  : _buildImagePlaceholder(colorScheme),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(
    ColorScheme colorScheme, {
    bool isLoading = false,
    bool hasError = false,
    double? progress,
  }) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(
        child:
            isLoading
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, value: progress),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                )
                : Icon(
                  hasError ? Icons.broken_image : Icons.movie_outlined,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  size: hasError ? 24 : 32,
                ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(theme, isTablet, isDesktop),
        SizedBox(height: isTablet ? 10 : 8),
        _buildRatingAndMetadata(colorScheme, isTablet),
        SizedBox(height: isTablet ? 10 : 8),
        if (!isCompact) _buildGenres(colorScheme, isTablet),
        const Spacer(),
        _buildEpisodesAndStatus(theme, colorScheme, isTablet),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, bool isTablet, bool isDesktop) {
    return Text(
      anime.title,
      style: (isDesktop
              ? theme.textTheme.titleLarge
              : isTablet
              ? theme.textTheme.titleMedium
              : theme.textTheme.titleMedium)
          ?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
      maxLines: isCompact ? 1 : (isTablet ? 3 : 2),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRatingAndMetadata(ColorScheme colorScheme, bool isTablet) {
    final iconSize = isTablet ? 16.0 : 14.0;
    final fontSize = isTablet ? 13.0 : 12.0;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : 8,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: iconSize, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                anime.score.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : 8,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Text(
            anime.type ?? 'TV',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenres(ColorScheme colorScheme, bool isTablet) {
    if (anime.genres == null || anime.genres!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              anime.genres!.take(isTablet ? 4 : 3).map((genre) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 8 : 6,
                    vertical: isTablet ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
        ),
        SizedBox(height: isTablet ? 10 : 8),
      ],
    );
  }

  Widget _buildEpisodesAndStatus(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isTablet,
  ) {
    final iconSize = isTablet ? 18.0 : 16.0;
    final fontSize = isTablet ? 13.0 : 11.0;

    return Row(
      children: [
        Icon(
          Icons.play_circle_outline_rounded,
          size: iconSize,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '${anime.episodes} eps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 8 : 6,
              vertical: isTablet ? 4 : 2,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(anime.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _getStatusColor(anime.status).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              anime.status,
              style: TextStyle(
                fontSize: fontSize,
                color: _getStatusColor(anime.status),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_forward_ios_rounded, size: isTablet ? 18 : 16),
        onPressed: onTap,
        color: colorScheme.onSurface.withOpacity(0.7),
        tooltip: 'View Details',
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
      case 'airing':
      case 'currently airing':
        return Colors.green.shade600;
      case 'finished':
      case 'completed':
      case 'finished airing':
        return Colors.blue.shade600;
      case 'upcoming':
      case 'not yet aired':
      case 'not_yet_aired':
        return Colors.orange.shade600;
      case 'on hold':
      case 'hiatus':
        return Colors.purple.shade600;
      case 'cancelled':
      case 'dropped':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
