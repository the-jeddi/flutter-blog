import 'package:flutter/material.dart';
import 'package:flutter_blog/core/providers/theme_provider.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/posts/screens/feed_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ResponsiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveShell({super.key, required this.navigationShell});

  // Switch branches
  void _goBranch(int index) {
    if (index == navigationShell.currentIndex) {
      if (index == 0) {
        FeedScreen.globalKey.currentState?.scrollToTop();
      }
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if on desktop-width screen
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final themeProvider = context.watch<ThemeProvider>();
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // The Desktop Side Menu
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              // Pushes the theme toggle to the very bottom
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      tooltip: 'Toggle Theme',
                      onPressed: () => themeProvider.toggleTheme(!isDark),
                    ),
                  ),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.feed_outlined),
                  selectedIcon: Icon(Icons.feed),
                  label: Text('Feed'),
                ),
                NavigationRailDestination(
                  icon: Icon(
                    isAuthenticated ? Icons.person_outline : Icons.login,
                  ),
                  selectedIcon: Icon(
                    isAuthenticated ? Icons.person : Icons.login,
                  ),
                  label: Text(isAuthenticated ? 'Profile' : 'Login'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // The active screen content
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // The Mobile Layout
    return Scaffold(
      body: navigationShell,
      // Material 3 Bottom Navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(isAuthenticated ? Icons.person_outline : Icons.login),
            selectedIcon: Icon(isAuthenticated ? Icons.person : Icons.login),
            label: isAuthenticated ? 'Profile' : 'Login',
          ),
        ],
      ),
    );
  }
}
