import 'dart:typed_data';

import 'package:flutter_blog/features/comments/models/comment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentRepository {
  final SupabaseClient _client;

  CommentRepository({required this._client});

  Future<List<Comment>> fetchComments(String postId) async {
    final rawList = await _client
        .from('comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return rawList.map((json) => Comment.fromJson(json)).toList();
  }

  Future<void> createComment({
    required String postId,
    required String content,
    required List<Uint8List> imageBytesList,
    required List<String> fileNames,
    required String authorId,
  }) async {
    final List<String> uploadedPaths = [];
    final List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < imageBytesList.length; i++) {
        final bytes = imageBytesList[i];
        final fileName = fileNames[i];

        final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
        final storagePath =
            'comment-$authorId-${DateTime.now().millisecondsSinceEpoch}-$i.$ext';

        await _client.storage
            .from('comment_images')
            .uploadBinary(storagePath, bytes);
        uploadedPaths.add(storagePath);

        final url = _client.storage
            .from('comment_images')
            .getPublicUrl(storagePath);
        uploadedUrls.add(url);
      }

      await _client.from('comments').insert({
        'post_id': postId,
        'content': content,
        'image_urls': uploadedUrls,
        'author_id': authorId,
      });
    } catch (e) {
      if (uploadedPaths.isNotEmpty) {
        await _client.storage.from('comment_images').remove(uploadedPaths);
      }
      rethrow;
    }
  }

  Future<Comment> updateComment({
    required String commentId,
    required String content,
    required String authorId,
    required List<String> keptImageUrls,
    required List<String> imagesToDelete,
    required List<Uint8List> newImageBytesList,
    required List<String> newFileNames,
  }) async {
    if (imagesToDelete.isNotEmpty) {
      final List<String> pathsToDelete = imagesToDelete.map((url) {
        return url.split('/comment_images/').last;
      }).toList();
      await _client.storage.from('comment_images').remove(pathsToDelete);
    }

    final List<String> newUploadedUrls = [];
    for (int i = 0; i < newImageBytesList.length; i++) {
      final bytes = newImageBytesList[i];
      final fileName = newFileNames[i];

      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final storagePath =
          'comment-$authorId-${DateTime.now().millisecondsSinceEpoch}-$i.$ext';

      await _client.storage
          .from('comment_images')
          .uploadBinary(storagePath, bytes);
      final url = _client.storage
          .from('comment_images')
          .getPublicUrl(storagePath);
      newUploadedUrls.add(url);
    }

    final finalImageUrls = [...keptImageUrls, ...newUploadedUrls];

    final data = await _client
        .from('comments')
        .update({
          'content': content,
          'image_urls': finalImageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', commentId)
        .select('*, profiles(*)')
        .single();

    return Comment.fromJson(data);
  }

  Future<void> deleteComment(String commentId, List<String> imageUrls) async {
    if (imageUrls.isNotEmpty) {
      final List<String> pathsToDelete = imageUrls.map((url) {
        return url.split('/comment_images/').last;
      }).toList();
      await _client.storage.from('comment_images').remove(pathsToDelete);
    }
    await _client.from('comments').delete().eq('id', commentId);
  }
}
