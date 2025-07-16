import 'package:abogados/screens/resolution/alternative_resolution_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../internships/internship_screen.dart';
import '../appointments/lawyer_appointments_screen.dart';
import '../appointments/client_appointments_screen.dart';
import '../mediation/mediation_screen.dart';
import '../virtual_classroom/virtual_classroom_screen.dart';
import '../forum/forum_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart'; // Nueva importación

class AppDrawer extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    return Drawer(
      child: Column(
        children: [
          // Cabecera del drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  user?.email ?? 'Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                // Solo mostrar tipo de usuario si está autenticado
                if (user != null)
                  FutureBuilder<UserType>(
                    future: _authService.getUserType(user.uid),
                    builder: (context, snapshot) {
                      String userType = 'Cargando...';
                      if (snapshot.connectionState == ConnectionState.done) {
                        userType = snapshot.data == UserType.lawyer
                            ? 'Abogado'
                            : 'Cliente';
                      }
                      return Text(
                        userType,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Opciones del menú
          Expanded(
            child: _buildMenuOptions(context, user),
          ),
          
          // Opción de cerrar sesión
          _buildLogoutOption(context),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context, User? user) {
    if (user == null) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Iniciar Sesión'),
            onTap: () {
              Navigator.pop(context);
              // Navegar a la pantalla de inicio de sesión
              // Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      );
    }

    return FutureBuilder<UserType>(
      future: _authService.getUserType(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final userType = snapshot.data ?? UserType.client;
        final bool isLawyer = userType == UserType.lawyer;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // NUEVA SECCIÓN: Asistente de IA Legal
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.smart_toy, color: Colors.cyan),
              ),
              title: Text('Asistente de IA Legal'),
              subtitle: Text('Chat inteligente y clasificación'),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIAssistantScreen(isLawyer: isLawyer),
                  ),
                );
              },
            ),

            Divider(thickness: 1, color: Colors.grey.shade300),
            
            // Sección de Vacantes (visible para todos)
            ListTile(
              leading: Icon(Icons.work),
              title: Text('Vacantes para Pasantes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InternshipScreen(isLawyer: isLawyer),
                  ),
                );
              },
            ),
            
            // Citas - La pantalla depende del tipo de usuario
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text(isLawyer ? 'Gestionar Citas' : 'Mis Citas'),
              onTap: () {
                Navigator.pop(context);
                if (isLawyer) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LawyerAppointmentsScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientAppointmentsScreen(),
                    ),
                  );
                }
              },
            ),

            Divider(),

            // OTRAS SECCIONES EXISTENTES
            
            // Medios Alternativos de Resolución de Conflictos
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.balance, color: Colors.purple),
              ),
              title: Text('Medios Alternativos'),
              subtitle: Text('Mediación y Arbitraje'),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NUEVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlternativeResolutionScreen(isLawyer: isLawyer),
                  ),
                );
              },
            ),
            
            // Aula Virtual
            ListTile(
              leading: Icon(Icons.menu_book, color: Colors.green),
              title: Text('Aula Virtual'),
              subtitle: Text('Recursos educativos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VirtualClassroomScreen(isLawyer: isLawyer),
                  ),
                );
              },
            ),
            
            // Foro
            ListTile(
              leading: Icon(Icons.forum, color: Colors.orange),
              title: Text('Foro'),
              subtitle: Text('Discusiones y consultas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForumScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoutOption(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    if (user == null) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // Opcional: Navegar a la pantalla de inicio
              // Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}