import 'package:abogados/screens/chat/all_chats_screen.dart';
import 'package:abogados/screens/chat/available_chats_screen.dart';
import 'package:abogados/screens/chat/live_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'lawyer_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  late Future<UserType> _userTypeFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    final userType = Provider.of<UserType?>(context, listen: false) ?? UserType.client;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userType == UserType.lawyer
              ? 'Presiona el botón verde para gestionar las consultas de clientes'
              : 'Presiona el botón verde para iniciar una consulta con un abogado'
        ),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  });
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _userTypeFuture = _authService.getUserType(user.uid);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      // Si no hay usuario autenticado, redirigir a la pantalla de inicio de sesión
      return LoginScreen();
    }

    return FutureBuilder<UserType>(
      future: _userTypeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userType = snapshot.data ?? UserType.client;

        // Lista de pantallas dependiendo del tipo de usuario
        final List<Widget> _screens = userType == UserType.lawyer
            ? [
                LawyerListScreen(),
                SearchScreen(),
                ProfileScreen(isLawyer: true),
              ]
            : [
                LawyerListScreen(),
                SearchScreen(),
                ProfileScreen(isLawyer: false),
              ];

        return Scaffold(
          appBar: AppBar(
            title: Text(_getAppBarTitle(_currentIndex, userType)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: _signOut,
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: _screens[_currentIndex],
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (userType == UserType.lawyer) {
                // Para abogados, mostrar la pantalla de gestión de todos los chats
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllChatsScreen(),
                  ),
                );
              } else {
                // Para clientes, ir directamente al chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveChatScreen(userType: userType),
                  ),
                );
              }
            },
            backgroundColor: Colors.green,
            child: Icon(Icons.chat, color: Colors.white),
            tooltip: userType == UserType.lawyer
                ? 'Gestionar consultas'
                : 'Consultar abogado',
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Abogados',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Buscar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle(int index, UserType userType) {
    switch (index) {
      case 0:
        return 'Abogados Disponibles';
      case 1:
        return 'Buscar Abogados';
      case 2:
        return userType == UserType.lawyer
            ? 'Mi Perfil Profesional'
            : 'Mi Perfil';
      default:
        return 'Abogados App';
    }
  }
}
