import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blog/core/locator.dart';
import 'package:flutter_blog/features/auth/repositories/auth_repository.dart';
import 'package:flutter_blog/features/profile/models/profile_model.dart';
import 'package:flutter_blog/features/profile/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepo = locator<ProfileRepository>();
  final AuthRepository _authRepo = locator<AuthRepository>();

  StreamSubscription<AuthState>? _authStateSubscription;

  Profile? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  Profile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isProfileSetup => _currentProfile != null;

  ProfileProvider() {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authStateSubscription = _authRepo.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // Fetch profile on login or app start
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        if (session?.user != null) {
          _loadProfile(session!.user.id);
        }
      }
      // Clear profile when logging out
      else if (event == AuthChangeEvent.signedOut) {
        _clearProfile();
      }
    });
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String userId) async {
    _startLoading();
    try {
      _currentProfile = await _profileRepo.fetchProfile(userId);
    } catch (e) {
      _setError('Failed to load profile');
    } finally {
      _stopLoading();
    }
  }

  Future<void> setupProfile(
    String userId,
    String displayName,
    Uint8List? imageBytes,
    String? fileName,
  ) async {
    _startLoading();
    try {
      _currentProfile = await _profileRepo.createProfile(
        userId,
        displayName,
        imageBytes,
        fileName,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to create profile');
    } finally {
      _stopLoading();
    }
  }

  void _clearProfile() {
    _currentProfile = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
