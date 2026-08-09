import 'dart:typed_data';

import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepository {
  final SupabaseClient _client;
  PostRepository({required this._client});

  Future<List<Post>> fetchPosts({required int page, required int limit}) async {
    final startIndex = page * limit;
    final endIndex = startIndex + limit - 1;

    // Fetch posts
    final rawList = await _client
        .from('posts')
        .select('*, profiles(*)')
        .order('created_at', ascending: false)
        .range(startIndex, endIndex);

    return rawList.map((json) => Post.fromJson(json)).toList();
  }

  Future<void> createPost({
    required String title,
    required String content,
    List<Uint8List> imageBytesList = const [],
    List<String> fileNames = const [],
    required String authorId,
  }) async {
    final List<String> uploadedPaths = [];
    final List<String> uploadedUrls = [];

    try {
      // Handle multipe image uplaod
      for (int i = 0; i < imageBytesList.length; i++) {
        final bytes = imageBytesList[i];
        final fileName = fileNames[i];

        final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
        final storagePath =
            '$authorId-${DateTime.now().millisecondsSinceEpoch}-$i.$ext'; // Highly unique name

        await _client.storage
            .from('post_images')
            .uploadBinary(storagePath, bytes);

        uploadedPaths.add(storagePath);

        final url = _client.storage
            .from('post_images')
            .getPublicUrl(storagePath);
        uploadedUrls.add(url);
      }

      // Insert post to database
      await _client.from('posts').insert({
        'title': title,
        'content': content,
        'image_urls': uploadedUrls,
        'author_id': authorId,
      });
    } catch (e) {
      // Rollback: If the DB insert fails (e.g., due to an RLS policy),
      // delete any images we successfully uploaded to prevent storage leaks.
      if (uploadedPaths.isNotEmpty) {
        await _client.storage.from('post_images').remove(uploadedPaths);
      }
      rethrow;
    }
  }
}
