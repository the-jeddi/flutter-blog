import 'dart:typed_data';

import 'package:flutter_blog/features/profile/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository({required this._client});

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile> createProfile(
    String userId,
    String displayName,
    Uint8List? imageBytes,
    String? fileName,
  ) async {
    String? avatarUrl;

    if (imageBytes != null && fileName != null) {
      // Extract extension
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final storageFileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage
          .from('avatars')
          .uploadBinary(storageFileName, imageBytes);

      avatarUrl = _client.storage.from('avatars').getPublicUrl(storageFileName);
    }

    final data = await _client
        .from('profiles')
        .insert({
          'id': userId,
          'display_name': displayName,
          'avatar_url': ?avatarUrl,
        })
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile({
    required String userId,
    required String displayName,
    Uint8List? newImageBytes,
    String? newFileName,
    String? oldAvatarUrl,
  }) async {
    String? avatarUrl = oldAvatarUrl;

    // Upload new image and delete the old one to prevent storage leaks
    if (newImageBytes != null && newFileName != null) {
      if (oldAvatarUrl != null) {
        try {
          final oldPath = oldAvatarUrl.split('/avatars/').last;
          await _client.storage.from('avatars').remove([oldPath]);
        } catch (_) {
          // Ignore if old file doesn't exist
        }
      }

      final ext = newFileName.contains('.')
          ? newFileName.split('.').last
          : 'jpg';
      final storageFileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage
          .from('avatars')
          .uploadBinary(storageFileName, newImageBytes);
      avatarUrl = _client.storage.from('avatars').getPublicUrl(storageFileName);
    }

    // Update database row
    final data = await _client
        .from('profiles')
        .update({
          'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        })
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(data);
  }
}
