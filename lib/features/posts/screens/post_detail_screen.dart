import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/comments/models/comment_model.dart';
import 'package:flutter_blog/features/comments/providers/comment_provider.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:flutter_blog/features/posts/widgets/post_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();

  final List<Uint8List> _newImageBytesList = [];
  final List<String> _newFileNames = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments(widget.post.id);
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final xFiles = await picker.pickMultiImage();
    if (xFiles.isNotEmpty) {
      for (final xFile in xFiles) {
        final bytes = await xFile.readAsBytes();
        setState(() {
          _newImageBytesList.add(bytes);
          _newFileNames.add(xFile.name);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _newImageBytesList.removeAt(index);
      _newFileNames.removeAt(index);
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _newImageBytesList.isEmpty) return;

    FocusScope.of(context).unfocus();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final provider = context.read<CommentProvider>();

    final success = await provider.createComment(
      postId: widget.post.id,
      content: content,
      imageBytesList: _newImageBytesList,
      fileNames: _newFileNames,
      authorId: userId,
    );

    if (mounted) {
      if (success) {
        _commentController.clear();
        setState(() {
          _newImageBytesList.clear();
          _newFileNames.clear();
        });
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    }
  }

  Future<void> _showEditCommentDialog(Comment comment) async {
    final contentController = TextEditingController(text: comment.content);
    List<String> keptImageUrls = List<String>.from(comment.imageUrls);
    List<String> deletedImageUrls = [];
    List<Uint8List> newImageBytes = [];
    List<String> newFileNames = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Comment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final xFiles = await picker.pickMultiImage();
                        if (xFiles.isNotEmpty) {
                          for (final xFile in xFiles) {
                            final bytes = await xFile.readAsBytes();
                            setDialogState(() {
                              newImageBytes.add(bytes);
                              newFileNames.add(xFile.name);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Images'),
                    ),
                    const SizedBox(height: 16),

                    // Image Preview in Dialog
                    if (keptImageUrls.isNotEmpty || newImageBytes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 80,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                keptImageUrls.length + newImageBytes.length,
                                (index) {
                                  final isExisting =
                                      index < keptImageUrls.length;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          child: isExisting
                                              ? Image.network(
                                                  keptImageUrls[index],
                                                  height: 80,
                                                  width: 80,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.memory(
                                                  newImageBytes[index -
                                                      keptImageUrls.length],
                                                  height: 80,
                                                  width: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                if (isExisting) {
                                                  deletedImageUrls.add(
                                                    keptImageUrls.removeAt(
                                                      index,
                                                    ),
                                                  );
                                                } else {
                                                  final removeIdx =
                                                      index -
                                                      keptImageUrls.length;
                                                  newImageBytes.removeAt(
                                                    removeIdx,
                                                  );
                                                  newFileNames.removeAt(
                                                    removeIdx,
                                                  );
                                                }
                                              });
                                            },
                                            child: const CircleAvatar(
                                              radius: 10,
                                              backgroundColor: Colors.black54,
                                              child: Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = contentController.text.trim();

                    Navigator.pop(
                      dialogContext,
                    ); // Close dialog synchronously first

                    _handleCommentUpdate(
                      commentId: comment.id,
                      content: text,
                      authorId: comment.authorId,
                      keptImageUrls: keptImageUrls,
                      deletedImageUrls: deletedImageUrls,
                      newImageBytes: newImageBytes,
                      newFileNames: newFileNames,
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCommentUpdate({
    required String commentId,
    required String content,
    required String authorId,
    required List<String> keptImageUrls,
    required List<String> deletedImageUrls,
    required List<Uint8List> newImageBytes,
    required List<String> newFileNames,
  }) async {
    final provider = context.read<CommentProvider>();

    final success = await provider.updateComment(
      commentId: commentId,
      content: content,
      authorId: authorId,
      keptImageUrls: keptImageUrls,
      imagesToDelete: deletedImageUrls,
      newImageBytesList: newImageBytes,
      newFileNames: newFileNames,
    );

    // Single mounted check guards the State's context after the async gap
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteCommentDialog(
    Comment comment,
    CommentProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text(
          'Are you sure you want to delete this? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.deleteComment(
        comment.id,
        comment.imageUrls,
      );
      if (mounted && !success && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = context.watch<CommentProvider>();
    final currentUserId = context.read<AuthProvider>().currentUser?.id;

    // Sync edit of posts in Post Detail Screen
    final postProvider = context.watch<PostProvider>();
    Post currentPost = widget.post;
    final feedIndex = postProvider.posts.indexWhere(
      (p) => p.id == widget.post.id,
    );
    if (feedIndex != -1) {
      currentPost = postProvider.posts[feedIndex];
    } else {
      // Check if it's in the user's profile feed
      final userIndex = postProvider.userPosts.indexWhere(
        (p) => p.id == widget.post.id,
      );
      if (userIndex != -1) {
        currentPost = postProvider.userPosts[userIndex];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          // Scrollable Post and Comments Area
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PostCard(post: currentPost, isDetailView: true),
                ),
                const SliverToBoxAdapter(child: Divider()),

                if (commentProvider.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (commentProvider.comments.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No comments yet. Be the first!'),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCommentItem(
                        commentProvider.comments[index],
                        currentUserId,
                        commentProvider,
                      ),
                      childCount: commentProvider.comments.length,
                    ),
                  ),
              ],
            ),
          ),

          // Sticky Bottom Input Area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_newImageBytesList.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImageBytesList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.memory(
                                      _newImageBytesList[index],
                                      height: 72,
                                      width: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: _pickImages,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.lightGreen,
                          ),
                          onPressed: commentProvider.isLoading
                              ? null
                              : _submitComment,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    Comment comment,
    String? currentUserId,
    CommentProvider provider,
  ) {
    final isOwner = currentUserId == comment.authorId;
    final hasAvatar =
        comment.author?.avatarUrl != null &&
        comment.author!.avatarUrl!.isNotEmpty;

    // Check if comment is edited
    final isEdited =
        comment.updatedAt != null &&
        comment.updatedAt!.difference(comment.createdAt).inSeconds > 0;
    final formattedDate = DateFormat.yMMMd().add_jm().format(
      comment.createdAt.toLocal(),
    );
    final displayDate = isEdited ? '$formattedDate (edited)' : formattedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage: hasAvatar
                ? NetworkImage(comment.author!.avatarUrl!)
                : null,
            child: !hasAvatar
                ? const Icon(Icons.person, size: 16, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.author?.displayName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (isOwner)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditCommentDialog(comment);
                          } else if (value == 'delete') {
                            _showDeleteCommentDialog(comment, provider);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Text(
                  displayDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 4),
                if (comment.content.isNotEmpty)
                  Text(comment.content, style: const TextStyle(fontSize: 14)),
                if (comment.imageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: comment.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                comment.imageUrls[index],
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
