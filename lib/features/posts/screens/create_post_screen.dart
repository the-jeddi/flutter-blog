import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/posts/models/post_model.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? existingPost;
  const CreatePostScreen({super.key, this.existingPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  // Existing images
  late List<String> _keptImageUrls;
  final List<String> _deletedImageUrls = [];

  // New images
  final List<Uint8List> _newImageBytesList = [];
  final List<String> _newFileNames = [];

  bool get isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingPost?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingPost?.content ?? '',
    );

    _keptImageUrls = List<String>.from(widget.existingPost?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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

  void _removeExistingImage(int index) {
    setState(() {
      final removedUrl = _keptImageUrls.removeAt(index);
      _deletedImageUrls.add(removedUrl);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageBytesList.removeAt(index);
      _newFileNames.removeAt(index);
    });
  }

  Future<void> _submitPost(PostProvider provider) async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      // Grab logged-in user's ID
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) return;

      bool success = false;

      if (isEditing) {
        success = await provider.updatePost(
          postId: widget.existingPost!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          authorId: userId,
          keptImageUrls: _keptImageUrls,
          imagesToDelete: _deletedImageUrls,
          newImageBytesList: _newImageBytesList,
          newFileNames: _newFileNames,
        );
      } else {
        await provider.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageBytesList: _newImageBytesList,
          fileNames: _newFileNames,
          authorId: userId,
        );
        success = provider.errorMessage == null;
      }

      if (!mounted) return;

      if (!success && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Post' : 'Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Picker
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
              ),

              const SizedBox(height: 16),
              _buildImagePreview(),
              const SizedBox(height: 32),

              Consumer<PostProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoadingInitial
                        ? null
                        : () => _submitPost(provider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoadingInitial
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update Post' : 'Post'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final totalImages = _keptImageUrls.length + _newImageBytesList.length;
    if (totalImages == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages,
        itemBuilder: (context, index) {
          // Check if index is existing
          final isExistingImage = index < _keptImageUrls.length;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: isExistingImage
                      ? Image.network(
                          _keptImageUrls[index],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          _newImageBytesList[index - _keptImageUrls.length],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      if (isExistingImage) {
                        _removeExistingImage(index);
                      } else {
                        _removeNewImage(index - _keptImageUrls.length);
                      }
                    },
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
