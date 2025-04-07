import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getCurrentUser();
    
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rememberMe');
      
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _currentUser?.email?.split('@').first ?? 'Usuario';
    final userEmail = _currentUser?.email ?? '';
    final userPhoto = _currentUser?.userMetadata?['avatar_url'] as String?;

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
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF143E40).withOpacity(0.1),
                    backgroundImage: userPhoto != null 
                        ? NetworkImage(userPhoto) 
                        : null,
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
          ],
        ),
      ),
    );
  }

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