import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_service.dart' as business_service;
import 'reservations_history.dart';
import 'map_screen.dart'; // Asegúrate de que este importe la clase correcta

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _businessesFuture;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  int _activeReservationsCount = 0;

  @override
  void initState() {
    super.initState();
    _businessesFuture = _fetchBusinesses();
    _pageController.addListener(_updateCurrentPage);
    _loadActiveReservationsCount();
  }

  void _updateCurrentPage() {
    setState(() {
      _currentPage = _pageController.page?.round() ?? 0;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchBusinesses() async {
    try {
      final response = await _supabase
          .from('barbershops')
          .select('id, name, address, city, cover_url, logo_url, rating')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching businesses: $e');
      throw Exception('Error al cargar negocios');
    }
  }

  Future<void> _loadActiveReservationsCount() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        final businessService = Provider.of<business_service.BusinessService>(context, listen: false);
        final appointments = await businessService.getUserActiveAppointments(session.user.id);
        if (mounted) {
          setState(() {
            _activeReservationsCount = appointments.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading reservations: $e');
    }
  }

  Future<void> _refreshBusinesses() async {
    try {
      setState(() {
        _businessesFuture = _fetchBusinesses();
      });
      await _loadActiveReservationsCount();
    } catch (e) {
      debugPrint('Error refreshing businesses: $e');
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateCurrentPage);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            // Search Bar
            _buildSearchBar(),
            
            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshBusinesses,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Businesses Carousel
                      _buildBusinessesCarousel(),
                      
                      // Divider
                      _buildDivider(),
                      
                      // Proximity Search Button
                      _buildProximitySearchButton(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF143E40),
              ),
            ),
            Text(
              'to groomly!',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF143E40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search new places...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessesCarousel() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: SizedBox(
        height: 250,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _businessesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No se encontraron negocios'));
            }

            final businesses = snapshot.data!;
            return Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: businesses.length,
                    itemBuilder: (context, index) {
                      return _buildBusinessCard(context, businesses[index]);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    businesses.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? const Color(0xFF143E40)
                            : Colors.grey.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[400],
              thickness: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey[400],
              thickness: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximitySearchButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(), // Cambiado de ModernMapScreen a MapScreen
            ),
          );
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: const DecorationImage(
              image: AssetImage('assets/images/busqueda.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'LOCATE BY PROXIMITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF143E40), size: 32),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF143E40), size: 32),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreen(), // Cambiado de ModernMapScreen a MapScreen
                    ),
                  );
                },
              ),
              const SizedBox(width: 60),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Color(0xFF143E40), size: 32),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReservationsHistoryScreen(),
                        ),
                      );
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
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF143E40), size: 32),
                onPressed: () {
                  Navigator.pushNamed(context, '/account');
                },
              ),
            ],
          ),
          Positioned(
            top: -32,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF143E40),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6.0,
                    offset: const Offset(0, 3.0),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, Map<String, dynamic> business) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/business',
          arguments: business['id'],
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                business['cover_url'] ?? business['logo_url'] ?? 
                'https://via.placeholder.com/300x200?text=No+Image',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.business, size: 50, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business['name'] ?? 'Sin nombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business['address'] ?? 'Sin dirección',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (business['rating'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                business['rating'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}