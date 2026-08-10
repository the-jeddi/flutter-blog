import 'package:flutter_blog/features/profile/models/profile_model.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Profile? author;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? author,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }
}
