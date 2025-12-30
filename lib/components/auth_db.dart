import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDb {
  AuthDb({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
}