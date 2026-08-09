import 'package:flutter/material.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    final profile = profileProvider.currentProfile;

    // Show loader if profile is missing
    if (profile == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if user has valid avatar URL
    final hasAvatar =
        profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: hasAvatar
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              Consumer<AuthProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              await provider.logout();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                      ),
                      icon: provider.isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.logout),
                      label: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log Out'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
