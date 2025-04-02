import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      // Cerrar sesión en Firebase
      await FirebaseAuth.instance.signOut();
      
      // Eliminar preferencia "rememberMe"
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rememberMe');
      
      // Navegar a la pantalla de login
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuario';
    final userEmail = user?.email ?? '';
    final userPhoto = user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Mi Cuenta',
          style: GoogleFonts.poppins(
            color: const Color(0xFF143E40),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF143E40)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado de usuario mejorado
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF143E40).withOpacity(0.1),
                    backgroundImage: userPhoto != null 
                        ? NetworkImage(userPhoto) 
                        : const AssetImage('assets/images/user_profile.png') as ImageProvider,
                    child: userPhoto == null 
                        ? Icon(Icons.person, size: 40, color: const Color(0xFF143E40))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF143E40),
                    ),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lista de opciones con logout
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSettingItem(
                    icon: Icons.lock,
                    title: 'Cambiar contraseña',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    icon: Icons.fingerprint,
                    title: 'Touch ID / Face ID',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    icon: Icons.language,
                    title: 'Idioma',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    icon: Icons.help,
                    title: 'Ayuda y soporte',
                    subtitle: 'Centro de ayuda y preguntas frecuentes',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Cerrar sesión',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF143E40),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _logout(context),
                    ),
                  ),
                ],
              ),
            ),

            // Footer consistente
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
                        onPressed: () => Navigator.pushNamed(context, '/home'),
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
                        onPressed: () {},
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

  // Widget reutilizable para ítems de configuración
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF143E40).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF143E40), size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}