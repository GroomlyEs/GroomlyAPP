import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  _BusinessScreenState createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final List<String> barberImages = const [
    'assets/images/elite.jpg',
    'assets/images/don_barbero.jpg',
    'assets/images/barnacut.png',
  ];

  int _currentPage = 0;

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
        title: Text(
          'ELiT3 TATTOO',
          style: GoogleFonts.poppins(
            color: const Color(0xFF143E40),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Slider de imágenes con indicadores
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
                      itemCount: barberImages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.asset(
                          barberImages[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Indicadores de página
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    barberImages.length,
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
            ),
          ),

          // Contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del negocio
                  Text(
                    'Elite Tattoo Barber',
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
                        'Miranda Street, Cornelia',
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
                          'OPEN',
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
                  
                  // Selectores de fecha y hora
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF143E40),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Select date',
                                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hour',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF143E40),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Select time',
                                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                                  ),
                                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Selector de barbero
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barber',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF143E40),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select barber',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 24, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Servicios
                  Text(
                    'SERVICES',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF143E40),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildServiceItem(
                    name: 'Basic hair cut',
                    duration: '30 min',
                    price: '14€',
                  ),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  _buildServiceItem(
                    name: 'Hair cut + beard',
                    duration: '45 min',
                    price: '17€',
                  ),
                ],
              ),
            ),
          ),
          
          // Botón DONE
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF143E40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'DONE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required String name,
    required String duration,
    required String price,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF143E40)),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF143E40),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                duration,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.poppins(
            color: const Color(0xFF143E40),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}