// services/business_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todos los negocios
  Future<List<Map<String, dynamic>>> getBusinesses() async {
    try {
      final response = await _supabase
          .from('barbershops')
          .select('id, name, address, city, logo_url, cover_url, rating')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch businesses: ${e.toString()}');
    }
  }

  // Obtener detalles de un negocio específico
  Future<Map<String, dynamic>> getBusinessDetails(String businessId) async {
    try {
      final response = await _supabase
          .from('barbershops')
          .select('*')
          .eq('id', businessId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch business details: ${e.toString()}');
    }
  }

  // Obtener negocios favoritos del usuario
  Future<List<Map<String, dynamic>>> getFavoriteBusinesses() async {
    try {
      final session = await _getSession();
      if (session == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('favorites')
          .select('barbershops(*)')
          .eq('user_id', session.user.id);

      return List<Map<String, dynamic>>.from(response.map((item) => item['barbershops']));
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch favorites: ${e.toString()}');
    }
  }

  // Añadir negocio a favoritos
  Future<void> addFavorite(String businessId) async {
    try {
      final session = await _getSession();
      if (session == null) throw Exception('User not authenticated');

      await _supabase.from('favorites').insert({
        'user_id': session.user.id,
        'barbershop_id': businessId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add favorite: ${e.toString()}');
    }
  }

  // Eliminar negocio de favoritos
  Future<void> removeFavorite(String businessId) async {
    try {
      final session = await _getSession();
      if (session == null) throw Exception('User not authenticated');

      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', session.user.id)
          .eq('barbershop_id', businessId);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove favorite: ${e.toString()}');
    }
  }

  // Verificar si un negocio es favorito
  Future<bool> isFavorite(String businessId) async {
    try {
      final session = await _getSession();
      if (session == null) return false;

      final response = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', session.user.id)
          .eq('barbershop_id', businessId);

      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check favorite: ${e.toString()}');
    }
  }

  // Método privado para obtener la sesión (similar a AuthService)
  Future<Session?> _getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken != null) {
        await _supabase.auth.recoverSession(accessToken);
        return _supabase.auth.currentSession;
      }
      return null;
    } catch (e) {
      throw Exception('Error getting session: ${e.toString()}');
    }
  }
}