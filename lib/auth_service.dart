import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse?> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      // 1. Registrar usuario en Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (authResponse.user == null) {
        throw Exception('User registration failed - no user returned');
      }

      // 2. Autenticar inmediatamente después del registro
      final loginResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (loginResponse.session == null) {
        throw Exception('Authentication failed after sign up');
      }

      // 3. Guardar sesión localmente
      await _saveSessionData(loginResponse.session!);

      // 4. Crear perfil en la tabla user_profiles
      final profileResponse = await _supabase.from('user_profiles').insert({
        'user_id': authResponse.user!.id,
        'first_name': firstName,
        'last_name': lastName,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();

      if (profileResponse.isEmpty) {
        await _supabase.auth.signOut();
        throw Exception('Profile creation failed');
      }

      return authResponse;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      // Limpiar cualquier estado en caso de error
      await _supabase.auth.signOut();
      await _clearSessionData();
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
      throw Exception('Session recovery failed: ${e.toString()}');
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updateData = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', userId);

      if (response.error != null) {
        throw Exception('Error updating profile: ${response.error!.message}');
      }
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }
}