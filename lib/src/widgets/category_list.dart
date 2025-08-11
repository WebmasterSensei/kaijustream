import 'package:flutter/material.dart';

class AnimeCategory {
  final IconData icon;
  final String name;
  final Color color;
  final String? description;
  final int? genreId; // For API integration

  const AnimeCategory({
    required this.icon,
    required this.name,
    required this.color,
    this.description,
    this.genreId,
  });
}

class CategoryList extends StatefulWidget {
  final Function(AnimeCategory)? onCategorySelected;
  final bool showDescriptions;
  final double itemHeight;

  const CategoryList({
    super.key,
    this.onCategorySelected,
    this.showDescriptions = false,
    this.itemHeight = 100,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  int? _selectedIndex;

  // Enhanced category data with descriptions and genre IDs
  final List<AnimeCategory> categories = const [
    AnimeCategory(
      icon: Icons.sports_martial_arts,
      name: 'Shounen',
      color: Colors.orange,
      description: 'Action-packed stories targeting young boys',
      genreId: 27,
    ),
    AnimeCategory(
      icon: Icons.favorite_border,
      name: 'Shoujo',
      color: Colors.pink,
      description: 'Romance and slice-of-life for young girls',
      genreId: 25,
    ),
    AnimeCategory(
      icon: Icons.psychology_alt,
      name: 'Seinen',
      color: Colors.blueGrey,
      description: 'Mature themes for adult men',
      genreId: 42,
    ),
    AnimeCategory(
      icon: Icons.face_4,
      name: 'Josei',
      color: Colors.purple,
      description: 'Realistic romance for adult women',
      genreId: 43,
    ),
    AnimeCategory(
      icon: Icons.child_friendly,
      name: 'Kodomo',
      color: Colors.green,
      description: 'Family-friendly content for children',
      genreId: 15,
    ),
    AnimeCategory(
      icon: Icons.flash_on,
      name: 'Action',
      color: Colors.red,
      description: 'High-energy battles and adventures',
      genreId: 1,
    ),
    AnimeCategory(
      icon: Icons.travel_explore,
      name: 'Adventure',
      color: Colors.teal,
      description: 'Epic journeys and exploration',
      genreId: 2,
    ),
    AnimeCategory(
      icon: Icons.emoji_emotions,
      name: 'Comedy',
      color: Colors.yellow,
      description: 'Hilarious and lighthearted stories',
      genreId: 4,
    ),
    AnimeCategory(
      icon: Icons.theater_comedy,
      name: 'Drama',
      color: Colors.deepOrange,
      description: 'Emotional and character-driven narratives',
      genreId: 8,
    ),
    AnimeCategory(
      icon: Icons.house,
      name: 'Slice of Life',
      color: Colors.brown,
      description: 'Everyday life and relationships',
      genreId: 36,
    ),
    AnimeCategory(
      icon: Icons.auto_awesome,
      name: 'Fantasy',
      color: Colors.indigo,
      description: 'Magical worlds and mythical creatures',
      genreId: 10,
    ),
    AnimeCategory(
      icon: Icons.nightlight_round,
      name: 'Supernatural',
      color: Colors.deepPurple,
      description: 'Paranormal and otherworldly phenomena',
      genreId: 37,
    ),
    AnimeCategory(
      icon: Icons.memory,
      name: 'Sci-Fi',
      color: Colors.cyan,
      description: 'Futuristic technology and space',
      genreId: 24,
    ),
    AnimeCategory(
      icon: Icons.dangerous,
      name: 'Horror',
      color: Colors.black,
      description: 'Spine-chilling and terrifying tales',
      genreId: 14,
    ),
    AnimeCategory(
      icon: Icons.search,
      name: 'Mystery',
      color: Colors.grey,
      description: 'Puzzles and detective work',
      genreId: 7,
    ),
    AnimeCategory(
      icon: Icons.favorite,
      name: 'Romance',
      color: Colors.pinkAccent,
      description: 'Love stories and relationships',
      genreId: 22,
    ),
    AnimeCategory(
      icon: Icons.hourglass_full,
      name: 'Psychological',
      color: Colors.amber,
      description: 'Mind-bending and thought-provoking',
      genreId: 40,
    ),
    AnimeCategory(
      icon: Icons.public,
      name: 'Isekai',
      color: Colors.lightBlue,
      description: 'Transported to another world',
      genreId: 62,
    ),
    AnimeCategory(
      icon: Icons.smart_toy,
      name: 'Mecha',
      color: Colors.blueAccent,
      description: 'Giant robots and mechanical suits',
      genreId: 18,
    ),
    AnimeCategory(
      icon: Icons.sports_volleyball,
      name: 'Sports',
      color: Colors.lightGreen,
      description: 'Athletic competitions and teamwork',
      genreId: 30,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showAllCategories(context);
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: widget.itemHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedIndex == index;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildCategoryItem(
                  category: category,
                  index: index,
                  isSelected: isSelected,
                  context: context,
                ),
              );
            },
          ),
        ),
        if (widget.showDescriptions && _selectedIndex != null) ...[
          const SizedBox(height: 8),
          _buildCategoryDescription(categories[_selectedIndex!], context),
        ],
      ],
    );
  }

  Widget _buildCategoryItem({
    required AnimeCategory category,
    required int index,
    required bool isSelected,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _onCategoryTap(category, index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 64 : 56,
              height: isSelected ? 64 : 56,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: category.color.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Icon(
                category.icon,
                color: Colors.white,
                size: isSelected ? 32 : 28,
              ),
            ),
            const SizedBox(height: 6),
            // Category name
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                    fontSize: 11,
                  ) ??
                  const TextStyle(),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDescription(
    AnimeCategory category,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(category.name),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: category.color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(category.icon, color: category.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: category.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      category.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryTap(AnimeCategory category, int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });

    // Call the callback if provided
    widget.onCategorySelected?.call(category);

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(category.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${category.name} selected'),
          ],
        ),
        backgroundColor: category.color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAllCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => _AllCategoriesSheet(
                  categories: categories,
                  scrollController: scrollController,
                  onCategorySelected: (category) {
                    Navigator.pop(context);
                    widget.onCategorySelected?.call(category);
                  },
                ),
          ),
    );
  }
}

class _AllCategoriesSheet extends StatelessWidget {
  final List<AnimeCategory> categories;
  final ScrollController scrollController;
  final Function(AnimeCategory)? onCategorySelected;

  const _AllCategoriesSheet({
    required this.categories,
    required this.scrollController,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'All Categories',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Grid of categories
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildGridCategoryItem(category, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCategoryItem(AnimeCategory category, BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onCategorySelected?.call(category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (category.description != null) ...[
              const SizedBox(height: 4),
              Text(
                category.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
