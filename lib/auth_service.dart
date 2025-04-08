import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse?> signUpWithEmail(
    String email, 
    String password, 
    Map<String, dynamic> userData
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );

      if (response.session != null) {
        await _saveSessionData(response.session!);
      }
      
      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      throw Exception('Error getting user: ${e.toString()}');
    }
  }

  Future<Session?> getSession() async {
    try {
      return _supabase.auth.currentSession;
    } catch (e) {
      throw Exception('Error getting session: ${e.toString()}');
    }
  }

  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        await _saveSessionData(response.session!);
      }
      
      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearSessionData();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<void> _saveSessionData(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', session.accessToken);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.setBool('isLoggedIn', false);
  }

  Future<bool> hasSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (isLoggedIn && accessToken != null) {
        final session = await getSession();
        return session != null && session.accessToken == accessToken;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> recoverSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken != null) {
        await _supabase.auth.recoverSession(accessToken);
      }
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  hasValidSession() {}
}