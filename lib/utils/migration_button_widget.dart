import 'package:flutter/material.dart';
import 'quick_migration_fix.dart'; // Asegúrate de importar el archivo correcto

class QuickMigrationButton extends StatefulWidget {
  @override
  _QuickMigrationButtonState createState() => _QuickMigrationButtonState();
}

class _QuickMigrationButtonState extends State<QuickMigrationButton> {
  bool _isRunning = false;
  String _status = '';

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Ejecutando migración...';
    });

    try {
      QuickCityMigration migration = QuickCityMigration();
      await migration.autoFix();
      
      setState(() {
        _status = '✅ Migración completada exitosamente';
      });
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migración completada. Ahora puedes usar los filtros por ciudad.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en migración: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              SizedBox(width: 8),
              Text(
                'Migración Necesaria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Se detectó que algunos abogados no tienen ciudad asignada. Ejecuta la migración para habilitar los filtros por ciudad.',
            style: TextStyle(
              color: Colors.orange[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isRunning ? null : _runMigration,
            icon: _isRunning 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync),
            label: Text(
              _isRunning ? 'Ejecutando...' : 'Ejecutar Migración de Ciudades',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_status.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('✅') ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _status.contains('✅') ? Colors.green[300]! : Colors.red[300]!,
                ),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('✅') ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget más simple para agregar en cualquier lugar
class SimpleMigrationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        // Mostrar dialog de confirmación
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Ejecutar Migración'),
            content: Text('¿Ejecutar la migración de ciudades para abogados?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Ejecutar'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Mostrar loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ejecutando migración...'),
                ],
              ),
            ),
          );

          try {
            QuickCityMigration migration = QuickCityMigration();
            await migration.autoFix();
            
            Navigator.pop(context); // Cerrar loading
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Migración completada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            Navigator.pop(context); // Cerrar loading
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: Icon(Icons.sync),
      label: Text('Migrar Ciudades'),
      backgroundColor: Colors.orange,
    );
  }
}