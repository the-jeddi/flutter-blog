import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blog/features/auth/providers/auth_provider.dart';
import 'package:flutter_blog/features/posts/providers/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<Uint8List> _imageBytesList = [];
  final List<String> _fileNames = [];

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
          _imageBytesList.add(bytes);
          _fileNames.add(xFile.name);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageBytesList.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  Future<void> _submitPost(PostProvider provider) async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      // Grab logged-in user's ID
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) return;

      await provider.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageBytesList: _imageBytesList,
        fileNames: _fileNames,
        authorId: userId,
      );

      if (!mounted) return;

      if (provider.errorMessage != null) {
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
      appBar: AppBar(title: const Text('Create Post')),
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
                icon: const Icon(Icons.image),
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
                        : const Text('Post'),
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
    if (_imageBytesList.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imageBytesList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    _imageBytesList[index],
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
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
