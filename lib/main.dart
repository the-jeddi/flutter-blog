import 'package:flutter/material.dart';
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
      ],
      child: const BlogApp(),
    )
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

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        // 1. Unauthenticated users trying to access protected routes
        if (!isLoggedIn && !isAuthRoute) {
          if (state.matchedLocation == '/feed') return null;
          return '/login';
        }

        // 2. Authenticated users trying to access login/register
        if (isLoggedIn && isAuthRoute) {
          return '/feed';
        }

        // Allowed routing
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder:(context, state) => const Scaffold(
            body: Center(child: Text('Login Page Placeholder')),
          ),
        ),
        GoRoute(
          path: '/feed',
          builder:(context, state) => const Scaffold(
            body: Center(child: Text('Feed Page Placeholder')),
          ),
        )
      ]
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