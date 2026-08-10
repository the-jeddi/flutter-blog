import 'dart:typed_data';

import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepository {
  final SupabaseClient _client;
  PostRepository({required this._client});

  Future<List<Post>> fetchPosts({
    required int page,
    required int limit,
    String? authorId,
    bool ascending = false,
  }) async {
    final startIndex = page * limit;
    final endIndex = startIndex + limit - 1;

    var query = _client.from('posts').select('*, profiles(*)');

    // Filter by author if an ID is provided
    if (authorId != null) {
      query = query.eq('author_id', authorId);
    }

    // Fetch posts
    final rawList = await query
        .order('created_at', ascending: ascending)
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

  Future<void> deletePost(String postId, List<String> imageUrls) async {
    // Delete images from storage
    if (imageUrls.isNotEmpty) {
      final List<String> pathsToDelete = imageUrls.map((url) {
        return url.split('/post_images/').last;
      }).toList();

      await _client.storage.from('post_images').remove(pathsToDelete);
    }

    // Delete post from database
    await _client.from('posts').delete().eq('id', postId);
  }

  Future<Post> updatePost({
    required String postId,
    required String title,
    required String content,
    required String authorId,
    required List<String> keptImageUrls,
    required List<String> imagesToDelete,
    required List<Uint8List> newImageBytesList,
    required List<String> newFileNames,
  }) async {
    // Delete removed images from storage
    if (imagesToDelete.isNotEmpty) {
      final List<String> pathsToDelete = imagesToDelete.map((url) {
        return url.split('/post_images/').last;
      }).toList();

      await _client.storage.from('post_images').remove(pathsToDelete);
    }

    // Upload brand new images
    final List<String> newUploadedUrls = [];
    for (int i = 0; i < newImageBytesList.length; i++) {
      final bytes = newImageBytesList[i];
      final fileName = newFileNames[i];

      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final storagePath =
          '$authorId-${DateTime.now().millisecondsSinceEpoch}-$i.$ext';

      await _client.storage
          .from('post_images')
          .uploadBinary(storagePath, bytes);

      final url = _client.storage.from('post_images').getPublicUrl(storagePath);
      newUploadedUrls.add(url);
    }

    // Combine existing url with brand new ones
    final finalImageUrls = [...keptImageUrls, ...newUploadedUrls];

    // Update database
    final data = await _client
        .from('posts')
        .update({
          'title': title,
          'content': content,
          'image_urls': finalImageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId)
        .select('*, profiles(*)')
        .single();

    return Post.fromJson(data);
  }
}
