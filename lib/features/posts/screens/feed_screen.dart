import 'package:flutter/material.dart';
import 'package:flutter_blog/core/widgets/responsive_app_bar.dart';
import 'package:flutter_blog/core/widgets/responsive_constrained_box.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:flutter_blog/features/posts/widgets/post_card.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  static final globalKey = GlobalKey<_FeedScreenState>();

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Attach scroll listener for infinite pagination
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadInitialPosts();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger fetch when within 200 pixel of bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostProvider>().loadMorePosts();
    }
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      context.read<PostProvider>().loadInitialPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return Scaffold(
      appBar: ResponsiveAppBar(title: const Text('The Daily Bits')),
      floatingActionButton: isAuthenticated
          ? FloatingActionButton(
              onPressed: () => context.push('/create-post'),
              child: const Icon(Icons.add),
            )
          : null,
      body: ResponsiveConstrainedBox(
        child: Consumer<PostProvider>(
          builder: (context, provider, child) {
            // Initial load
            if (provider.isLoadingInitial && provider.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // No posts found
            if (!provider.isLoadingInitial && provider.posts.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => provider.loadInitialPosts(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 150),
                    Center(
                      child: Text(
                        'No posts yet. Be the first to share!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Feed list
            return RefreshIndicator(
              onRefresh: () => provider.loadInitialPosts(),
              child: ListView.builder(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                itemCount:
                    provider.posts.length + (provider.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // Render bottom loading spinner
                  if (index == provider.posts.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Render post card
                  final post = provider.posts[index];
                  return PostCard(post: post);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
