import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getBusinesses() async {
    try {
      final response = await _supabase
          .from('barbershops')
          .select('id, name, address, city, logo_url, cover_url, rating')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener negocios: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getBusinessDetails(String businessId) async {
    try {
      final response = await _supabase
          .from('barbershops')
          .select('*')
          .eq('id', businessId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al obtener detalles del negocio: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getBarbers(String businessId) async {
    try {
      final response = await _supabase
          .from('barbers')
          .select('*')
          .eq('barbershop_id', businessId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener barberos: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getServices(String businessId) async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('barbershop_id', businessId)
          .eq('is_active', true)
          .order('price', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener servicios: ${e.toString()}');
    }
  }

  Future<String> createOrder({
    required String businessId,
    required String userId,
    required String barberId,
    required List<Map<String, dynamic>> services,
    required DateTime appointmentTime,
    String? notes,
  }) async {
    try {
      final totalDuration = services.fold(
        0, 
        (sum, service) => sum + (service['duration'] as int)
      );

      final appointmentResponse = await _supabase
          .from('appointments')
          .insert({
            'user_id': userId,
            'barbershop_id': businessId,
            'barber_id': barberId,
            'starts_at': appointmentTime.toIso8601String(),
            'duration': totalDuration,
            'status': 'confirmed',
            'notes': notes,
          })
          .select()
          .single();

      final appointmentId = appointmentResponse['id'] as String;

      for (final service in services) {
        await _supabase.from('appointment_services').insert({
          'appointment_id': appointmentId,
          'service_id': service['id'],
          'price': service['price'],
          'duration': service['duration'],
        });
      }

      return appointmentId;
    } catch (e) {
      throw Exception('Error al crear la reserva: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(
    String barberId, 
    DateTime date,
    int serviceDuration,
  ) async {
    try {
      final scheduleResponse = await _supabase
          .from('barber_schedule')
          .select('opens_at, closes_at, break_start, break_end')
          .eq('barber_id', barberId)
          .eq('day_of_week', date.weekday);

      if (scheduleResponse.isEmpty) {
        throw Exception('El barbero no tiene horario para este día');
      }

      final schedule = scheduleResponse[0];
      
      if (schedule['opens_at'] == null || schedule['closes_at'] == null) {
        throw Exception('Horario incompleto en la base de datos');
      }

      final opensAtTime = _parseTimeString(schedule['opens_at'] as String);
      final closesAtTime = _parseTimeString(schedule['closes_at'] as String);
      final breakStartTime = schedule['break_start'] != null 
          ? _parseTimeString(schedule['break_start'] as String)
          : null;
      final breakEndTime = schedule['break_end'] != null
          ? _parseTimeString(schedule['break_end'] as String)
          : null;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final existingAppointmentsResponse = await _supabase
          .from('appointments')
          .select('starts_at, duration')
          .eq('barber_id', barberId)
          .gte('starts_at', startOfDay.toIso8601String())
          .lt('starts_at', endOfDay.toIso8601String())
          .neq('status', 'cancelled');

      final bookedSlots = (existingAppointmentsResponse as List).map((appt) {
        return {
          'start': DateTime.parse(appt['starts_at'] as String),
          'end': DateTime.parse(appt['starts_at'] as String)
              .add(Duration(minutes: appt['duration'] as int)),
        };
      }).toList();

      final availableSlots = <Map<String, dynamic>>[];
      DateTime currentSlot = DateTime(
        date.year, date.month, date.day, 
        opensAtTime.hour, opensAtTime.minute
      );

      final closingDateTime = DateTime(
        date.year, date.month, date.day,
        closesAtTime.hour, closesAtTime.minute
      );

      while (currentSlot.add(Duration(minutes: serviceDuration)).isBefore(closingDateTime)) {
        final slotEnd = currentSlot.add(Duration(minutes: serviceDuration));
        
        bool isDuringBreak = false;
        if (breakStartTime != null && breakEndTime != null) {
          final breakStart = DateTime(
            date.year, date.month, date.day,
            breakStartTime.hour, breakStartTime.minute
          );
          final breakEnd = DateTime(
            date.year, date.month, date.day,
            breakEndTime.hour, breakEndTime.minute
          );
          
          isDuringBreak = currentSlot.isBefore(breakEnd) && slotEnd.isAfter(breakStart);
        }

        bool isAvailable = !isDuringBreak;
        for (final booked in bookedSlots) {
          if (currentSlot.isBefore(booked['end']!) && slotEnd.isAfter(booked['start']!)) {
            isAvailable = false;
            break;
          }
        }

        if (isAvailable) {
          availableSlots.add({
            'hour': currentSlot.hour,
            'minute': currentSlot.minute,
            'formatted': '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}',
          });
        }

        currentSlot = currentSlot.add(const Duration(minutes: 30));
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Error al obtener horarios disponibles: ${e.toString()}');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Error al cancelar la cita: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserActiveAppointments(String userId) async {
    try {
      // Consulta corregida con joins explícitos
      final appointments = await _supabase
          .from('appointments')
          .select('*, barbers(name)')
          .eq('user_id', userId)
          .gte('starts_at', DateTime.now().toIso8601String())
          .neq('status', 'cancelled')
          .order('starts_at', ascending: true);

      // Obtener servicios para cada cita
      final result = <Map<String, dynamic>>[];
      for (final appointment in appointments) {
        final services = await _supabase
            .from('appointment_services')
            .select('*, services(name)')
            .eq('appointment_id', appointment['id']);

        result.add({
          ...appointment,
          'appointment_services': services,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener las citas del usuario: ${e.toString()}');
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}