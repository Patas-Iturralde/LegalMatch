import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_initializer.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  // Inicializar Flutter widgets
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase y datos de la aplicación
  await FirebaseInitializer.initialize();
  
  initializeDateFormatting('es_ES', null).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para el estado de autenticación del usuario
        StreamProvider<User?>.value(
          value: AuthService().user,
          initialData: null,
        ),
      ],
      
      child: MaterialApp(
        title: 'LurisMatch',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('es', 'ES'), // Español
          const Locale('en', 'US'), // Inglés (como respaldo)
        ],
        locale: const Locale('es', 'ES'), // Establece español como idioma predeterminado
        
        theme: ThemeData(
          // Colores principales
          primarySwatch: Colors.teal,
          primaryColor: Color.fromARGB(255, 15, 77, 62),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal,
            accentColor: Color.fromARGB(255, 15, 77, 62),
            brightness: Brightness.light,
          ),
          
          // Tema de texto
          fontFamily: 'Roboto',
          textTheme: TextTheme(
            displayLarge: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            displayMedium: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            displaySmall: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            bodyLarge: TextStyle(
              fontSize: 16.0,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(
              fontSize: 14.0,
              color: Colors.black54,
            ),
          ),
          
          // Densidad visual
          visualDensity: VisualDensity.adaptivePlatformDensity,
          
          // Tema para inputs
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          
          // Tema para botones elevados
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 2,
            ),
          ),
          
          // Tema para botones de texto
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          
          // Tema para tarjetas
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          
          // Tema para AppBar
          appBarTheme: AppBarTheme(
            backgroundColor: Color.fromARGB(255, 15, 77, 62),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
        ),
        
        // Ruta inicial
        home: AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtener el estado actual de autenticación desde el Provider
    final firebaseUser = Provider.of<User?>(context);
    
    // Mostrar la pantalla de carga mientras se verifica la autenticación
    if (firebaseUser == null) {
      // Verificar si está en proceso de autenticación o si realmente no hay sesión
      return FutureBuilder(
        future: Future.delayed(Duration(seconds: 2)), // Tiempo para mostrar la pantalla de carga
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else {
            // Si después del tiempo de espera no hay usuario, mostrar login
            return LoginScreen();
          }
        },
      );
    }
    
    // Si hay un usuario autenticado, mostrar la pantalla principal
    return HomeScreen();
  }
}

// Clase para gestionar las rutas nombradas (opcional, para expansión futura)
class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String lawyerDetail = '/lawyer-detail';
  static const String profile = '/profile';
  static const String search = '/search';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      // Otras rutas pueden ser añadidas aquí a medida que crece la aplicación
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no definida para ${settings.name}'),
            ),
          ),
        );
    }
  }
}