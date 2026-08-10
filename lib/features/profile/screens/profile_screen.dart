import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:flutter_blog/features/posts/widgets/post_card.dart';
import 'package:flutter_blog/features/profile/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<PostProvider>().loadUserPosts(
          userId,
          ascending: _isAscending,
        );
      }
    });
  }

  void _toggleSort() {
    setState(() {
      _isAscending = !_isAscending;
    });
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<PostProvider>().loadUserPosts(
        userId,
        ascending: _isAscending,
      );
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final currentProfile = profileProvider.currentProfile;
    if (currentProfile == null) return;

    final nameController = TextEditingController(
      text: currentProfile.displayName,
    );
    Uint8List? newImageBytes;
    String? newFileName;

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while potentially saving
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final xFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (xFile != null) {
                          final bytes = await xFile.readAsBytes();
                          setDialogState(() {
                            newImageBytes = bytes;
                            newFileName = xFile.name;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: newImageBytes != null
                            ? MemoryImage(newImageBytes!)
                            : (currentProfile.avatarUrl != null
                                  ? NetworkImage(currentProfile.avatarUrl!)
                                        as ImageProvider
                                  : null),
                        child:
                            newImageBytes == null &&
                                currentProfile.avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to change avatar',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(dialogContext);

                    _handleProfileUpdate(
                      profileProvider: profileProvider,
                      postProvider: postProvider,
                      userId: currentProfile.id,
                      newDisplayName: name,
                      newImageBytes: newImageBytes,
                      newFileName: newFileName,
                      oldAvatarUrl: currentProfile.avatarUrl,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleProfileUpdate({
    required ProfileProvider profileProvider,
    required PostProvider postProvider,
    required String userId,
    required String newDisplayName,
    required Uint8List? newImageBytes,
    required String? newFileName,
    required String? oldAvatarUrl,
  }) async {
    final success = await profileProvider.updateProfile(
      userId: userId,
      displayName: newDisplayName,
      newImageBytes: newImageBytes,
      newFileName: newFileName,
      oldAvatarUrl: oldAvatarUrl,
    );

    // One simple mounted check guards the whole State context!
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      return;
    }

    await Future.wait([
      postProvider.loadInitialPosts(),
      postProvider.loadUserPosts(userId, ascending: _isAscending),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final postProvider = context.watch<PostProvider>();
    final authProvider = context.read<AuthProvider>();

    final profile = profileProvider.currentProfile;

    // Show loader if profile is missing
    if (profile == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if user has valid avatar URL
    final hasAvatar =
        profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Log Out',
            onPressed: () async => await authProvider.logout(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Static Profile Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: hasAvatar
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: !hasAvatar
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Show progress bar during profile update
                  if (profileProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                ],
              ),
            ),
          ),

          // Sorting Controls Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Posts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _toggleSort,
                    icon: Icon(
                      _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                    ),
                    label: Text(_isAscending ? 'Oldest First' : 'Newest First'),
                  ),
                ],
              ),
            ),
          ),

          // The List of User Posts (Will show a spinner while re-fetching)
          if (postProvider.isLoadingUserPosts)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (postProvider.userPosts.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('You haven\'t posted anything yet.'),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return PostCard(post: postProvider.userPosts[index]);
              }, childCount: postProvider.userPosts.length),
            ),
        ],
      ),
    );
  }
}
