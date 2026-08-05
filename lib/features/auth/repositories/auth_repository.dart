import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  // Dependency injection
  final SupabaseClient _client;
  AuthRepository({required this._client});

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Synchronous check for the current user
  User? get currentUser => _client.auth.currentUser;
}