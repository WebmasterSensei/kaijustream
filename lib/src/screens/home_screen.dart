import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:KaijuStream/src/screens/profile_screen.dart';
import 'package:KaijuStream/src/widgets/anime_list.dart';
import 'package:KaijuStream/src/widgets/anime_search.dart';
import 'package:KaijuStream/src/widgets/category_list.dart';
import 'package:KaijuStream/src/widgets/promo_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Haptic feedback for better UX
      HapticFeedback.selectionClick();

      // Animate FAB
      if (index == 1) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: _buildModernAppBar(context),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          HapticFeedback.selectionClick();
        },
        children: const [HomeContent(), AnimeSearchPage(), ProfileScreen()],
      ),
      // floatingActionButton: AnimatedBuilder(
      //   animation: _fabAnimationController,
      //   builder: (context, child) {
      //     return Transform.scale(
      //       scale: _fabAnimationController.value,
      //       child: FloatingActionButton(
      //         onPressed: () {
      //           // Add your search action here
      //           ScaffoldMessenger.of(context).showSnackBar(
      //             const SnackBar(content: Text('Quick search activated!')),
      //           );
      //         },
      //         backgroundColor: colorScheme.primary,
      //         child: Icon(
      //           Icons.search,
      //           color: colorScheme.onPrimary,
      //         ),
      //       ),
      //     );
      //   },
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // bottomNavigationBar: _buildModernBottomBar(context),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 4,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'KaijuStream',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            backgroundColor: colorScheme.error,
            child: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            // Add notification action
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outlined,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProfileScreen()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.search,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnimeSearchPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildModernBottomBar(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: colorScheme.surface,
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: colorScheme.shadow.withOpacity(0.1),
  //           blurRadius: 20,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(24),
  //       child: BottomNavigationBar(
  //         currentIndex: _currentIndex,
  //         onTap: _onTabTapped,
  //         elevation: 0,
  //         backgroundColor: Colors.transparent,
  //         selectedItemColor: colorScheme.primary,
  //         unselectedItemColor: colorScheme.onSurfaceVariant,
  //         type: BottomNavigationBarType.fixed,
  //         selectedFontSize: 12,
  //         unselectedFontSize: 12,
  //         items: [
  //           BottomNavigationBarItem(
  //             icon: AnimatedContainer(
  //               duration: const Duration(milliseconds: 200),
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: _currentIndex == 0
  //                     ? colorScheme.primaryContainer.withOpacity(0.3)
  //                     : Colors.transparent,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 _currentIndex == 0 ? Icons.home : Icons.home_outlined,
  //               ),
  //             ),
  //             label: 'Home',
  //           ),
  //           BottomNavigationBarItem(
  //             icon: AnimatedContainer(
  //               duration: const Duration(milliseconds: 200),
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: _currentIndex == 1
  //                     ? colorScheme.primaryContainer.withOpacity(0.3)
  //                     : Colors.transparent,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 _currentIndex == 1 ? Icons.search : Icons.search_outlined,
  //               ),
  //             ),
  //             label: 'Search',
  //           ),
  //           BottomNavigationBarItem(
  //             icon: AnimatedContainer(
  //               duration: const Duration(milliseconds: 200),
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: _currentIndex == 2
  //                     ? colorScheme.primaryContainer.withOpacity(0.3)
  //                     : Colors.transparent,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 _currentIndex == 2 ? Icons.person : Icons.person_outlined,
  //               ),
  //             ),
  //             label: 'Profile',
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: PromoCarousel()),
        const SliverToBoxAdapter(child: CategoryList()),
        SliverFillRemaining(
          hasScrollBody: true,
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 40,
            ), // Space for floating bottom bar
            child: const TopAnimePage(),
          ),
        ),
      ],
    );
  }
}
