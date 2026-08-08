import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_blog/core/locator.dart';
import 'package:flutter_blog/features/auth/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = locator<AuthRepository>();
  StreamSubscription<AuthState>? _authStateSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters for the UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authRepo.currentUser;
  bool get isAuthenticated => currentUser != null;

  AuthProvider() {
    // Listen to Supabase auth events
    _authStateSubscription = _authRepo.authStateChanges.listen((event) {
      notifyListeners();
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

  Future<void> login(String email, String password) async {
    _startLoading();
    try {
      await _authRepo.signIn(email, password);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred during login.');
    } finally {
      _stopLoading();
    }
  }

  Future<void> register(String email, String password) async {
    _startLoading();
    try {
      await _authRepo.signUp(email, password);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred during sign up.');
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    _startLoading();
    try {
      await _authRepo.signOut();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred during logout.');
    } finally {
      _stopLoading();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
