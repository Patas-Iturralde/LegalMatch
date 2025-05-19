import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../internships/internship_screen.dart';
import '../appointments/lawyer_appointments_screen.dart';
import '../appointments/client_appointments_screen.dart';

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
            
            // Perfil
            // ListTile(
            //   leading: Icon(Icons.person),
            //   title: Text('Mi Perfil'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     // Navegar a la pantalla de perfil
            //     // Navigator.pushNamed(context, '/profile');
            //   },
            // ),
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