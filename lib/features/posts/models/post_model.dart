import 'package:flutter_blog/features/profile/models/profile_model.dart';

class Post {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Profile? author;

  Post({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    this.author,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }
}
