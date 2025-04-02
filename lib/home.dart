import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> _barberShops = const [
    {
      'image': 'assets/images/elite.jpg',
      'name': 'Elite Tattoo Barber',
      'address': 'Miranda Street, Cornelia'
    },
    {
      'image': 'assets/images/don_barbero.jpg',
      'name': 'Don Barbero', 
      'address': 'Main Avenue, Barcelona'
    },
    {
      'image': 'assets/images/barnacut.png',
      'name': 'Barnacut',
      'address': 'Central Square, Madrid'
    },
    {
      'image': 'assets/images/barbellion.jpg',
      'name': 'Barbellion',
      'address': 'Riverside, Valencia'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            // Sección superior con título
            Container(
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
            ),

            // Barra de búsqueda
            Padding(
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
            ),

            // Contenido principal con scroll
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección horizontal de imágenes (modificada para ser clickeable)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: _barberShops.length,
                          itemBuilder: (context, index) {
                            final shop = _barberShops[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/business',
                                  arguments: {
                                    'name': shop['name'],
                                    'address': shop['address'],
                                    'image': shop['image'],
                                  },
                                );
                              },
                              child: Container(
                                width: 170,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: AssetImage(shop['image']!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Resto del código sin cambios...
                    Padding(
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
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                      child: GestureDetector(
                        onTap: () {},
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
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
                    ),
                  ],
                ),
              ),
            ),

            // Footer sin cambios
            Container(
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
                        icon: Icon(Icons.home, color: const Color(0xFF143E40), size: 32),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: const Color(0xFF143E40), size: 32),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 60),
                      IconButton(
                        icon: Icon(Icons.history, color: const Color(0xFF143E40), size: 32),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.person, color: const Color(0xFF143E40), size: 32),
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
            ),
          ],
        ),
      ),
    );
  }
}