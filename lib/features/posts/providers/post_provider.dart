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

  int _currentPage = 0;
  final int _limit = 10;

  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasReachedMax => _hasReachedMax;
  String? get errorMessage => _errorMessage;

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
    } catch (e) {
      _errorMessage = 'Failed to create post. Please try again';
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
