import 'package:flutter/material.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildTextContent(context),
          _buildImages(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasAvatar =
        post.author?.avatarUrl != null && post.author!.avatarUrl!.isNotEmpty;
    final formattedDate = DateFormat.yMMMMd().add_jm().format(
      post.createdAt.toLocal(),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: hasAvatar
            ? NetworkImage(post.author!.avatarUrl!)
            : null,
        child: !hasAvatar ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(
        post.author?.displayName ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        formattedDate,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
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
              borderRadius: BorderRadius.circular(8.0),
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
