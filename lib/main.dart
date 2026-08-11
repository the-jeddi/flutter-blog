import 'package:flutter/material.dart';
import 'package:flutter_blog/core/providers/theme_provider.dart';
import 'package:flutter_blog/core/theme/app_theme.dart';
import 'package:flutter_blog/core/widgets/responsive_shell.dart';
import 'package:flutter_blog/features/auth/screens/login_screen.dart';
import 'package:flutter_blog/features/auth/screens/register_screen.dart';
import 'package:flutter_blog/features/comments/providers/comment_provider.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:flutter_blog/features/posts/screens/create_post_screen.dart';
import 'package:flutter_blog/features/posts/screens/feed_screen.dart';
import 'package:flutter_blog/features/posts/screens/post_detail_screen.dart';
import 'package:flutter_blog/features/profile/providers/profile_provider.dart';
import 'package:flutter_blog/features/profile/screens/onboarding_screen.dart';
import 'package:flutter_blog/features/profile/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/locator.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: 'https://kskdaatllhsdxyhllllq.supabase.co',
    publishableKey: 'sb_publishable_vZDVtob8xuN3KunG5d7sEA_PVaveA3S',
  );

  // 2. Setup get_it Locator
  configureDependencies();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const BlogApp(),
    ),
  );
}

class BlogApp extends StatefulWidget {
  const BlogApp({super.key});

  @override
  State<BlogApp> createState() => _BlogAppState();
}

class _BlogAppState extends State<BlogApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    _router = GoRouter(
      initialLocation: '/feed',
      refreshListenable: Listenable.merge([authProvider, profileProvider]),
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isProfileSetup = profileProvider.isProfileSetup;
        final isProfileLoading = profileProvider.isLoading;

        final location = state.uri.path;
        final isAuthRoute = location == '/login' || location == '/register';
        final isOnboardingRoute = location == '/onboarding';

        // Define public routes
        final isPublicRoute =
            location == '/feed' ||
            location == '/' ||
            location.startsWith('/post/');

        // 1. Unauthenticated users trying to access protected routes
        if (!isLoggedIn) {
          if (isPublicRoute || isAuthRoute) return null;
          return '/login';
        }

        // 2. Prevent premature redirects while fetching the profile
        if (isProfileLoading) {
          return null;
        }

        // 3. Authenticated users but no profile setup
        if (!isProfileSetup) {
          return isOnboardingRoute ? null : '/onboarding';
        }

        // 4. Keep Authenticated and Profile Setup out of auth/onboarding
        if (isAuthRoute || isOnboardingRoute) {
          return '/feed';
        }

        // Allowed routing
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/create-post',
          builder: (context, state) {
            Post? post = state.extra as Post?;

            // WEB SWIPE-BACK FALLBACK
            if (post == null && state.uri.queryParameters.containsKey('id')) {
              if (post == null && state.uri.queryParameters.containsKey('id')) {
                final postId = state.uri.queryParameters['id'];
                final postProvider = context.read<PostProvider>();

                // Search both feeds for the missing post
                final allPosts = [
                  ...postProvider.posts,
                  ...postProvider.userPosts,
                ];
                final index = allPosts.indexWhere((p) => p.id == postId);
                if (index != -1) post = allPosts[index];
              }
            }

            return CreatePostScreen(existingPost: post);
          },
        ),
        GoRoute(
          path: '/post/:id',
          builder: (context, state) {
            Post? post = state.extra as Post?;

            // WEB SWIPE-BACK FALLBACK
            if (post == null) {
              final postId = state.pathParameters['id'];
              final postProvider = context.read<PostProvider>();
              final allPosts = [
                ...postProvider.posts,
                ...postProvider.userPosts,
              ];
              final index = allPosts.indexWhere((p) => p.id == postId);
              if (index != -1) post = allPosts[index];
            }

            // Failsafe if post was deleted or missing
            if (post == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Post not found. Please return to the feed.'),
                ),
              );
            }

            return PostDetailScreen(post: post);
          },
        ),

        // Inside Shell
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ResponsiveShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/feed',
                  builder: (context, state) =>
                      FeedScreen(key: FeedScreen.globalKey),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'The Daily Bits',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
