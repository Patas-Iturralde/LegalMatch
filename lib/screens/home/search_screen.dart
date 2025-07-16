import 'package:abogados/utils/migration_button_widget.dart';
import 'package:flutter/material.dart';
import '../../models/lawyer.dart';
import '../../services/lawyer_service.dart';
import '../../utils/ecuador_cities.dart';

import 'lawyer_detail_screen.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final LawyerService _lawyerService = LawyerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Lawyer> _searchResults = [];
  List<String> _specialties = [];
  List<String> _availableCities = [];
  
  String? _selectedSpecialty;
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  
  bool _isLoading = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    _loadAvailableCities();
    _performSearch(); // Cargar todos los abogados inicialmente
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadAvailableCities() async {
    try {
      final cities = await _lawyerService.getAvailableCities();
      setState(() {
        _availableCities = cities;
      });
    } catch (e) {
      print('Error al cargar ciudades: $e');
      // Fallback a todas las ciudades del Ecuador si hay error
      setState(() {
        _availableCities = EcuadorCities.getMajorCities();
      });
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _lawyerService.searchLawyers(
        name: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        specialty: _selectedSpecialty,
        city: _selectedCity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
      );

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error en la búsqueda: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la búsqueda')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSpecialty = null;
      _selectedCity = null;
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
    });
    _performSearch();
  }

  void _showPriceFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Precio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Precio mínimo (USD)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  _minPrice = double.tryParse(value);
                },
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Precio máximo (USD)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  _maxPrice = double.tryParse(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performSearch();
              },
              child: Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _showRatingFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Calificación Mínima'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecciona la calificación mínima:'),
              SizedBox(height: 16),
              ...List.generate(5, (index) {
                double rating = (index + 1).toDouble();
                return ListTile(
                  title: Row(
                    children: [
                      ...List.generate(rating.toInt(), (i) => Icon(Icons.star, color: Colors.amber, size: 20)),
                      ...List.generate(5 - rating.toInt(), (i) => Icon(Icons.star_border, size: 20)),
                      SizedBox(width: 8),
                      Text('$rating estrellas o más'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _minRating = rating;
                    });
                    Navigator.of(context).pop();
                    _performSearch();
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Mostrar botón de migración si no hay ciudades disponibles
     
            // QuickMigrationButton(),
          
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Campo de búsqueda principal
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar abogados por nombre...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.tune),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (value) => _performSearch(),
                ),
                
                // Filtros expandibles
                if (_showFilters) ...[
                  SizedBox(height: 16),
                  
                  // Filtros de especialidad y ciudad
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSpecialty,
                          decoration: InputDecoration(
                            labelText: 'Especialidad',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._specialties.map((specialty) {
                              return DropdownMenuItem<String>(
                                value: specialty,
                                child: Text(specialty, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSpecialty = value;
                            });
                            _performSearch();
                          },
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: InputDecoration(
                            labelText: _availableCities.isEmpty ? 'Sin ciudades (migrar)' : 'Ciudad',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _availableCities.isEmpty 
                              ? [DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Ejecutar migración primero'),
                                )]
                              : [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Todas'),
                                  ),
                                  ..._availableCities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city,
                                      child: Text(city, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                ],
                          onChanged: _availableCities.isEmpty ? null : (value) {
                            setState(() {
                              _selectedCity = value;
                            });
                            _performSearch();
                          },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Filtros adicionales
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showPriceFilterDialog,
                          icon: Icon(Icons.attach_money, size: 18),
                          label: Text(
                            _minPrice != null || _maxPrice != null
                                ? 'Precio: ${_minPrice?.toStringAsFixed(0) ?? "0"}-${_maxPrice?.toStringAsFixed(0) ?? "∞"}'
                                : 'Precio',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showRatingFilterDialog,
                          icon: Icon(Icons.star, size: 18),
                          label: Text(
                            _minRating != null
                                ? '${_minRating!.toStringAsFixed(0)}+ estrellas'
                                : 'Calificación',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearFilters,
                        icon: Icon(Icons.clear_all),
                        tooltip: 'Limpiar filtros',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Resultados de búsqueda
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron abogados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearFilters,
            child: Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final lawyer = _searchResults[index];
        return _buildLawyerCard(lawyer);
      },
    );
  }

  Widget _buildLawyerCard(Lawyer lawyer) {
    String? province = EcuadorCities.getProvinceOfCity(lawyer.city);
    String locationText = province != null ? '${lawyer.city}, $province' : lawyer.city;

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LawyerDetailScreen(lawyerId: lawyer.id),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Foto del abogado
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: lawyer.photoBase64.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(lawyer.photoBase64)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: lawyer.photoBase64.isEmpty
                    ? Icon(Icons.person, size: 30.0, color: Colors.grey[600])
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
                    
                    // Especialidades (mostrar solo las primeras 2)
                    Text(
                      lawyer.specialties.take(2).join(', ') + 
                      (lawyer.specialties.length > 2 ? '...' : ''),
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4.0),
                    
                    // Ciudad y provincia
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    
                    // Rating y precio
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