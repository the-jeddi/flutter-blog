import 'package:flutter/foundation.dart';
import 'package:flutter_blog/core/locator.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:flutter_blog/features/posts/repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _postRepo = locator<PostRepository>();

  List<Post> _posts = [];
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  List<Post> _userPosts = [];
  bool _isLoadingUserPosts = false;

  int _currentPage = 0;
  final int _limit = 10;

  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasReachedMax => _hasReachedMax;
  String? get errorMessage => _errorMessage;

  List<Post> get userPosts => _userPosts;
  bool get isLoadingUserPosts => _isLoadingUserPosts;

  Future<void> loadInitialPosts() async {
    _isLoadingInitial = true;
    _currentPage = 0;
    _hasReachedMax = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedPosts = await _postRepo.fetchPosts(
        page: _currentPage,
        limit: _limit,
      );

      _posts = fetchedPosts;

      // If posts are fewer than requested
      if (fetchedPosts.length < _limit) {
        _hasReachedMax = true;
      }
    } catch (e) {
      _errorMessage = 'Failed to load feed. Please try again';
    } finally {
      _isLoadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    // Prevent over fetching
    if (_isLoadingInitial || _isLoadingMore || _hasReachedMax) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newPosts = await _postRepo.fetchPosts(
        page: _currentPage,
        limit: _limit,
      );

      _posts.addAll(newPosts);

      if (newPosts.length < _limit) {
        _hasReachedMax = true;
      }
    } catch (e) {
      _errorMessage = 'Failed to load more posts';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadUserPosts(String userId, {bool ascending = false}) async {
    _isLoadingUserPosts = true;
    notifyListeners();

    try {
      // Fetch up to 50 posts for the profile view
      _userPosts = await _postRepo.fetchPosts(
        page: 0,
        limit: 50,
        authorId: userId,
        ascending: ascending,
      );
    } catch (e) {
      _errorMessage = 'Failed to load user posts.';
    } finally {
      _isLoadingUserPosts = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String title,
    required String content,
    List<Uint8List> imageBytesList = const [],
    List<String> fileNames = const [],
    required String authorId,
  }) async {
    _isLoadingInitial = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _postRepo.createPost(
        title: title,
        content: content,
        imageBytesList: imageBytesList,
        fileNames: fileNames,
        authorId: authorId,
      );

      // Refresh feed to show new post
      await loadInitialPosts();
      await loadUserPosts(authorId);
    } catch (e) {
      _errorMessage = 'Failed to create post. Please try again';
      _isLoadingInitial = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(String postId, List<String> imageUrls) async {
    try {
      await _postRepo.deletePost(postId, imageUrls);

      _posts.removeWhere((post) => post.id == postId);
      _userPosts.removeWhere((post) => post.id == postId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete post';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String title,
    required String content,
    required String authorId,
    required List<String> keptImageUrls,
    required List<String> imagesToDelete,
    required List<Uint8List> newImageBytesList,
    required List<String> newFileNames,
  }) async {
    _isLoadingInitial = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPost = await _postRepo.updatePost(
        postId: postId,
        title: title,
        content: content,
        authorId: authorId,
        keptImageUrls: keptImageUrls,
        imagesToDelete: imagesToDelete,
        newImageBytesList: newImageBytesList,
        newFileNames: newFileNames,
      );

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      final userIndex = _userPosts.indexWhere((p) => p.id == postId);
      if (userIndex != -1) {
        _userPosts[userIndex] = updatedPost;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update post. Please try again.';
      return false;
    } finally {
      _isLoadingInitial = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
