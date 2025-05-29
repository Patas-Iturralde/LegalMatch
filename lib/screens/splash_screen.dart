import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 15, 77, 62),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o ícono de la aplicación
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/logo_sf.png', // Asegúrate de tener un logo en esta ruta
              ),
            ),
            SizedBox(height: 24.0),
            
            // Nombre de la aplicación
            Text(
              'IurisMatch',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 12.0),
            
            // Eslogan
            Text(
              'Tu abogado de confianza a',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 48.0),
            
            // Indicador de carga
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}