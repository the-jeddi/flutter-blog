import 'package:flutter/foundation.dart';
import 'package:flutter_blog/core/locator.dart';
import 'package:flutter_blog/features/comments/models/comment_model.dart';
import 'package:flutter_blog/features/comments/repositories/comment_repository.dart';
import 'package:flutter_blog/features/profile/models/profile_model.dart';

class CommentProvider extends ChangeNotifier {
  final CommentRepository _repo = locator<CommentRepository>();

  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear previous comments immediately when switching posts
  Future<void> loadComments(String postId) async {
    _isLoading = true;
    _errorMessage = null;
    _comments = [];
    notifyListeners();

    try {
      _comments = await _repo.fetchComments(postId);
    } catch (e) {
      _errorMessage = 'Failed to load comments.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createComment({
    required String postId,
    required String content,
    List<Uint8List> imageBytesList = const [],
    List<String> fileNames = const [],
    required String authorId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createComment(
        postId: postId,
        content: content,
        imageBytesList: imageBytesList,
        fileNames: fileNames,
        authorId: authorId,
      );

      // Refresh to pull the new comment with joined profile data
      await loadComments(postId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to post comment.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComment({
    required String commentId,
    required String content,
    required String authorId,
    required List<String> keptImageUrls,
    required List<String> imagesToDelete,
    required List<Uint8List> newImageBytesList,
    required List<String> newFileNames,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedComment = await _repo.updateComment(
        commentId: commentId,
        content: content,
        authorId: authorId,
        keptImageUrls: keptImageUrls,
        imagesToDelete: imagesToDelete,
        newImageBytesList: newImageBytesList,
        newFileNames: newFileNames,
      );

      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = updatedComment;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update comment.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment(String commentId, List<String> imageUrls) async {
    try {
      await _repo.deleteComment(commentId, imageUrls);
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete comment.';
      notifyListeners();
      return false;
    }
  }

  void syncProfileUpdate(Profile updatedProfile) {
    bool hasChanges = false;
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].authorId == updatedProfile.id) {
        _comments[i] = _comments[i].copyWith(author: updatedProfile);
        hasChanges = true;
      }
    }
    if (hasChanges) notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
