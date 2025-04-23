import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'business_service.dart';
import 'reservations_history.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  _BusinessScreenState createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late String _businessId;
  late Future<Map<String, dynamic>> _businessFuture;
  late Future<List<Map<String, dynamic>>> _barbersFuture;
  late Future<List<Map<String, dynamic>>> _servicesFuture;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedBarberId;
  final Map<String, Map<String, dynamic>> _selectedServices = {};
  int _totalDuration = 0;
  double _totalPrice = 0.0;
  final TextEditingController _notesController = TextEditingController();
  
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  bool _isSubmitting = false;
  int _activeReservationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveReservationsCount();
  }

  Future<void> _loadActiveReservationsCount() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final businessService = Provider.of<BusinessService>(context, listen: false);
      final appointments = await businessService.getUserActiveAppointments(session.user.id);
      setState(() {
        _activeReservationsCount = appointments.length;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      _businessId = args;
      _loadData();
    } else {
      Navigator.pop(context);
    }
  }

  void _loadData() {
    final businessService = Provider.of<BusinessService>(context, listen: false);
    
    setState(() {
      _businessFuture = businessService.getBusinessDetails(_businessId);
      _barbersFuture = businessService.getBarbers(_businessId);
      _servicesFuture = businessService.getServices(_businessId);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_selectedBarberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un barbero primero')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF143E40),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // Verificar condiciones previas con mensajes más descriptivos
    if (_selectedBarberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona un barbero para ver los horarios disponibles')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha para ver los horarios disponibles')),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un servicio para calcular la duración')),
      );
      return;
    }

    try {
      final businessService = Provider.of<BusinessService>(context, listen: false);
      
      // Mostrar indicador de carga mientras se obtienen los horarios
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final availableSlots = await businessService.getAvailableTimeSlots(
        _selectedBarberId!,
        _selectedDate!,
        _totalDuration,
      );

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      if (availableSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay horarios disponibles para este día con la duración seleccionada')),
        );
        return;
      }

      // Convertir slots disponibles a TimeOfDay para el selector
      final availableTimes = availableSlots.map((slot) {
        return TimeOfDay(hour: slot['hour'], minute: slot['minute']);
      }).toList();

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? _findClosestAvailableTime(availableTimes),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF143E40),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: true,
              ),
              child: child!,
            ),
          );
        },
      );

      if (pickedTime != null) {
        // Verificar que la hora seleccionada está en los slots disponibles
        final isTimeValid = availableTimes.any((time) => 
          time.hour == pickedTime.hour && time.minute == pickedTime.minute);
        
        if (isTimeValid) {
          setState(() {
            _selectedTime = pickedTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor seleccione una hora disponible')),
          );
        }
      }
    } catch (e) {
      // Cerrar el diálogo de carga si hay un error
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener horarios: ${e.toString()}')),
      );
    }
  }

  // Método auxiliar para encontrar la hora disponible más cercana
  TimeOfDay _findClosestAvailableTime(List<TimeOfDay> availableTimes) {
    final now = TimeOfDay.now();
    for (final time in availableTimes) {
      if (time.hour > now.hour || (time.hour == now.hour && time.minute >= now.minute)) {
        return time;
      }
    }
    return availableTimes.first;
  }

  void _toggleServiceSelection(Map<String, dynamic> service) {
    setState(() {
      if (_selectedServices.containsKey(service['id'])) {
        _selectedServices.remove(service['id']);
        _totalDuration -= (service['duration'] as num).toInt();
        _totalPrice -= (service['price'] as num).toDouble();
      } else {
        _selectedServices[service['id']] = service;
        _totalDuration += (service['duration'] as num).toInt();
        _totalPrice += (service['price'] as num).toDouble();
      }
      
      _selectedTime = null;
    });
  }

  Future<void> _confirmOrder() async {
    if (_selectedDate == null || 
        _selectedTime == null || 
        _selectedBarberId == null || 
        _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final businessService = Provider.of<BusinessService>(context, listen: false);
    
    final session = _supabase.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión para realizar una reserva')),
      );
      return;
    }
    final userId = session.user.id;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final appointmentTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final activeAppointments = await businessService.getUserActiveAppointments(userId);
      if (activeAppointments.isNotEmpty) {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Ya tienes una reserva',
              style: GoogleFonts.poppins(
                color: const Color(0xFF143E40),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Ya tienes una reserva activa. ¿Deseas crear una nueva?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF143E40),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Continuar',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF143E40),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm != true) {
          return;
        }
      }

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Confirmar Reserva',
            style: GoogleFonts.poppins(
              color: const Color(0xFF143E40),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles de la reserva:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${DateFormat('EEE, d MMM yyyy', 'es_ES').format(_selectedDate!)}',
                style: GoogleFonts.poppins(),
              ),
              Text(
                'Hora: ${_selectedTime!.format(context)}',
                style: GoogleFonts.poppins(),
              ),
              Text(
                'Duración: $_totalDuration minutos',
                style: GoogleFonts.poppins(),
              ),
              Text(
                'Total: ${_totalPrice.toStringAsFixed(2)}€',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF143E40),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Confirmar',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF143E40),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final appointmentId = await businessService.createOrder(
          businessId: _businessId,
          userId: userId,
          barberId: _selectedBarberId!,
          services: _selectedServices.values.toList(),
          appointmentTime: appointmentTime,
          notes: _notesController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva confirmada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadActiveReservationsCount();

        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _selectedBarberId = null;
          _selectedServices.clear();
          _totalDuration = 0;
          _totalPrice = 0.0;
          _notesController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la reserva: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildServiceItem({
    required Map<String, dynamic> service,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF143E40)
                    : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(6),
              color: isSelected 
                  ? const Color(0xFF143E40).withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Color(0xFF143E40))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] ?? 'Sin nombre',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF143E40),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${service['duration']} min',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(service['price'] as num).toStringAsFixed(2)}€',
            style: GoogleFonts.poppins(
              color: const Color(0xFF143E40),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberDropdown(List<Map<String, dynamic>> barbers) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedBarberId,
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Seleccionar barbero',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        items: barbers.map((barber) {
          return DropdownMenuItem<String>(
            value: barber['id'],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                barber['name'] ?? 'Desconocido',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedBarberId = value;
            _selectedDate = null;
            _selectedTime = null;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _imageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF143E40)),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _businessFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }
            return Text(
              snapshot.data?['name'] ?? 'Negocio',
              style: GoogleFonts.poppins(
                color: const Color(0xFF143E40),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Color(0xFF143E40)),
                onPressed: () {
                  Navigator.pushNamed(context, '/reservations');
                },
              ),
              if (_activeReservationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeReservationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _businessFuture,
        builder: (context, businessSnapshot) {
          if (businessSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (businessSnapshot.hasError) {
            return Center(child: Text('Error: ${businessSnapshot.error}'));
          }

          final business = businessSnapshot.data!;
          final List<String> images = [
            business['cover_url'],
            business['logo_url'],
          ].whereType<String>().toList();

          return Column(
            children: [
              if (images.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 327,
                        height: 320,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: PageView.builder(
                            controller: _imageController,
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? const Color(0xFF143E40)
                                  : Colors.grey.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business['name'] ?? 'Sin nombre',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF143E40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            business['address'] ?? 'Sin dirección',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF143E40).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ABIERTO',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF143E40),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF143E40),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate != null
                                        ? DateFormat('EEE, d MMM', 'es_ES').format(_selectedDate!)
                                        : 'Seleccionar fecha',
                                    style: GoogleFonts.poppins(
                                      color: _selectedDate != null 
                                          ? Colors.black 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hora',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF143E40),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTime != null
                                        ? _selectedTime!.format(context)
                                        : 'Seleccionar hora',
                                    style: GoogleFonts.poppins(
                                      color: _selectedTime != null 
                                          ? Colors.black 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Barbero',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF143E40),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _barbersFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              
                              final barbers = snapshot.data ?? [];
                              return _buildBarberDropdown(barbers);
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'SERVICIOS',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF143E40),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _servicesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          
                          final services = snapshot.data ?? [];
                          
                          return Column(
                            children: [
                              ...services.map((service) {
                                final isSelected = _selectedServices.containsKey(service['id']);
                                return Column(
                                  children: [
                                    _buildServiceItem(
                                      service: service,
                                      isSelected: isSelected,
                                      onTap: () => _toggleServiceSelection(service),
                                    ),
                                    const Divider(height: 24, color: Color(0xFFEEEEEE)),
                                  ],
                                );
                              }),
                              if (services.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text('No hay servicios disponibles'),
                                ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notas adicionales',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF143E40),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Escribe aquí cualquier requerimiento especial...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  children: [
                    if (_selectedServices.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_totalPrice.toStringAsFixed(2)}€',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: const Color(0xFF143E40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF143E40),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'CONFIRMAR RESERVA',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}