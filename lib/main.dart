import 'package:flutter/material.dart';
import 'package:flutter_blog/features/auth/screens/login_screen.dart';
import 'package:flutter_blog/features/auth/screens/register_screen.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:flutter_blog/features/posts/screens/create_post_screen.dart';
import 'package:flutter_blog/features/posts/screens/feed_screen.dart';
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
      initialLocation: '/login',
      refreshListenable: Listenable.merge([authProvider, profileProvider]),
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isProfileSetup = profileProvider.isProfileSetup;
        final isProfileLoading = profileProvider.isLoading;

        final location = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/register';
        final isOnboardingRoute = location == '/onboarding';

        // 1. Unauthenticated users trying to access protected routes
        if (!isLoggedIn) {
          return isAuthRoute ? null : '/login';
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
        GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
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
        GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/create-post',
          builder: (context, state) {
            final post = state.extra as Post?;
            return CreatePostScreen(existingPost: post);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. Material App with go_router integration
    return MaterialApp.router(
      title: 'The Daily Bits',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
