import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o ícono de la aplicación
            Container(
              width: 120.0,
              height: 120.0,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gavel,
                size: 64.0,
                color: Colors.white,
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
              'Encuentra el mejor asesor legal',
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