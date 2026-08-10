import 'package:flutter/material.dart';
import 'package:flutter_blog/core/theme/app_theme.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool isDetailView;

  const PostCard({super.key, required this.post, this.isDetailView = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDetailView
          ? null
          : () => context.push('/post/{post.id}', extra: post),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTextContent(context),
            _buildImages(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasAvatar =
        post.author?.avatarUrl != null && post.author!.avatarUrl!.isNotEmpty;

    // Check if post is edited
    final isEdited =
        post.updatedAt != null &&
        post.updatedAt!.difference(post.createdAt).inSeconds > 0;
    final formattedDate = DateFormat.yMMMMd().add_jm().format(
      post.createdAt.toLocal(),
    );
    final displayDate = isEdited ? '$formattedDate (edited)' : formattedDate;

    // Check ownership
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isOwner = currentUserId == post.authorId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        backgroundImage: hasAvatar
            ? NetworkImage(post.author!.avatarUrl!)
            : null,
        child: !hasAvatar
            ? Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      title: Text(
        post.author?.displayName ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        displayDate,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),

      trailing: isOwner
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(context);
                } else if (value == 'edit') {
                  context.push('/create-post', extra: post);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    // Trigger delete
    final provider = context.read<PostProvider>();
    final success = await provider.deletePost(post.id, post.imageUrls);

    if (context.mounted && !success && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  Widget _buildTextContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    // No images attached
    if (post.imageUrls.isEmpty) {
      return SizedBox.shrink();
    }

    // Single image attached
    if (post.imageUrls.length == 1) {
      return Image.network(
        post.imageUrls.first,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // Multiple images attached
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: post.imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16.0 : 4.0,
              right: index == post.imageUrls.length - 1 ? 16.0 : 4.0,
              bottom: 16.0,
            ),
            child: ClipRRect(
              borderRadius: AppTheme.defaultBorderRadius,
              child: Image.network(
                post.imageUrls[index],
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
