import 'package:flutter/material.dart';
import '../../models/lawyer.dart';
import '../../services/lawyer_service.dart';
import 'lawyer_detail_screen.dart';
import 'dart:convert';

class LawyerListScreen extends StatefulWidget {
  @override
  _LawyerListScreenState createState() => _LawyerListScreenState();
}

class _LawyerListScreenState extends State<LawyerListScreen> {
  final LawyerService _lawyerService = LawyerService();
  List<String> _specialties = [];
  String? _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final specialties = await _lawyerService.getSpecialties();
      setState(() {
        _specialties = specialties;
      });
    } catch (e) {
      print('Error al cargar especialidades: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filtro por especialidad
          Padding(
            padding: EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filtrar por especialidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              value: _selectedSpecialty,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todas las especialidades'),
                ),
                ..._specialties.map((specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSpecialty = value;
                });
              },
            ),
          ),
          
          // Lista de abogados
          Expanded(
            child: _selectedSpecialty == null
                ? _buildLawyerList()
                : _buildLawyerListBySpecialty(_selectedSpecialty!),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerList() {
    return StreamBuilder<List<Lawyer>>(
      stream: _lawyerService.getLawyers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final lawyers = snapshot.data ?? [];
        
        if (lawyers.isEmpty) {
          return Center(
            child: Text('No hay abogados disponibles'),
          );
        }

        // Ordenar abogados por calificación (ranking) de mayor a menor
        lawyers.sort((a, b) => b.rating.compareTo(a.rating));

        return ListView.builder(
          itemCount: lawyers.length,
          itemBuilder: (context, index) {
            final lawyer = lawyers[index];
            return _buildLawyerCard(lawyer);
          },
        );
      },
    );
  }

  Widget _buildLawyerListBySpecialty(String specialty) {
    return StreamBuilder<List<Lawyer>>(
      stream: _lawyerService.getLawyersBySpecialty(specialty),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final lawyers = snapshot.data ?? [];
        
        if (lawyers.isEmpty) {
          return Center(
            child: Text('No hay abogados con la especialidad "$specialty"'),
          );
        }

        // Ordenar abogados por calificación (ranking) de mayor a menor
        lawyers.sort((a, b) => b.rating.compareTo(a.rating));

        return ListView.builder(
          itemCount: lawyers.length,
          itemBuilder: (context, index) {
            final lawyer = lawyers[index];
            return _buildLawyerCard(lawyer);
          },
        );
      },
    );
  }

  Widget _buildLawyerCard(Lawyer lawyer) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LawyerDetailScreen(lawyerId: lawyer.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto del abogado
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: lawyer.photoBase64.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(lawyer.photoBase64)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: lawyer.photoBase64.isEmpty
                    ? Icon(Icons.person, size: 40.0, color: Colors.grey[600])
                    : null,
              ),
              SizedBox(width: 16.0),
              
              // Información del abogado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      lawyer.specialty,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18.0),
                        SizedBox(width: 4.0),
                        Text(
                          lawyer.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          '(${lawyer.reviewCount})',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        Spacer(),
                        Text(
                          '\$${lawyer.consultationPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}