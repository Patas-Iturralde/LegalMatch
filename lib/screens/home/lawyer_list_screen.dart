import 'package:flutter/material.dart';
import '../../models/lawyer.dart';
import '../../services/lawyer_service.dart';
import '../../utils/ecuador_cities.dart';
import 'lawyer_detail_screen.dart';
import 'dart:convert';

class LawyerListScreen extends StatefulWidget {
  @override
  _LawyerListScreenState createState() => _LawyerListScreenState();
}

class _LawyerListScreenState extends State<LawyerListScreen> {
  final LawyerService _lawyerService = LawyerService();
  List<String> _specialties = [];
  List<String> _availableCities = [];
  String? _selectedSpecialty;
  String? _selectedCity;
  String _currentFilter = 'all'; // 'all', 'specialty', 'city', 'both'

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    _loadAvailableCities();
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
      // Fallback a ciudades principales si hay error
      setState(() {
        _availableCities = EcuadorCities.getMajorCities();
      });
    }
  }

  void _updateFilter() {
    if (_selectedSpecialty != null && _selectedCity != null) {
      _currentFilter = 'both';
    } else if (_selectedSpecialty != null) {
      _currentFilter = 'specialty';
    } else if (_selectedCity != null) {
      _currentFilter = 'city';
    } else {
      _currentFilter = 'all';
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecialty = null;
      _selectedCity = null;
      _currentFilter = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sección de filtros
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Filtrar Abogados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Spacer(),
                    if (_selectedSpecialty != null || _selectedCity != null)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: Icon(Icons.clear, size: 18),
                        label: Text('Limpiar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Filtro por especialidad
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por especialidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.gavel),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
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
                      _updateFilter();
                    });
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 12),
                
                // Filtro por ciudad
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por ciudad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.location_city),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las ciudades'),
                    ),
                    ..._availableCities.map((city) {
                      String? province = EcuadorCities.getProvinceOfCity(city);
                      String displayText = province != null ? '$city ($province)' : city;
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(displayText),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                      _updateFilter();
                    });
                  },
                  isExpanded: true,
                ),
                
                // Mostrar filtros activos
                if (_selectedSpecialty != null || _selectedCity != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtros activos: ${_getActiveFiltersText()}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Lista de abogados
          Expanded(
            child: _buildLawyerList(),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText() {
    List<String> activeFilters = [];
    
    if (_selectedSpecialty != null) {
      activeFilters.add('Especialidad: $_selectedSpecialty');
    }
    
    if (_selectedCity != null) {
      String? province = EcuadorCities.getProvinceOfCity(_selectedCity!);
      String cityText = province != null ? '$_selectedCity ($province)' : _selectedCity!;
      activeFilters.add('Ciudad: $cityText');
    }
    
    return activeFilters.join(' • ');
  }

  Widget _buildLawyerList() {
    // Determinar qué stream usar basado en los filtros
    Stream<List<Lawyer>> lawyerStream;
    
    switch (_currentFilter) {
      case 'specialty':
        lawyerStream = _lawyerService.getLawyersBySpecialty(_selectedSpecialty!);
        break;
      case 'city':
        lawyerStream = _lawyerService.getLawyersByCity(_selectedCity!);
        break;
      case 'both':
        lawyerStream = _lawyerService.getLawyersBySpecialtyAndCity(_selectedSpecialty!, _selectedCity!);
        break;
      default:
        lawyerStream = _lawyerService.getLawyers();
    }

    return StreamBuilder<List<Lawyer>>(
      stream: lawyerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Recargar
                  },
                  child: Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final lawyers = snapshot.data ?? [];
        
        if (lawyers.isEmpty) {
          return _buildEmptyState();
        }

        // Ordenar abogados por calificación (ranking) de mayor a menor
        lawyers.sort((a, b) => b.rating.compareTo(a.rating));

        return Column(
          children: [
            // Estadísticas de resultados
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${lawyers.length} abogado${lawyers.length != 1 ? 's' : ''} encontrado${lawyers.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Spacer(),
                  if (lawyers.isNotEmpty)
                    Icon(Icons.sort, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
            
            // Lista de abogados
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: lawyers.length,
                itemBuilder: (context, index) {
                  final lawyer = lawyers[index];
                  return _buildLawyerCard(lawyer, index + 1);
                },
              ),
            ),
          ],
        );
      },
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
            'No hay abogados disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          if (_selectedSpecialty != null || _selectedCity != null)
            ElevatedButton(
              onPressed: _clearFilters,
              child: Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    if (_selectedSpecialty != null && _selectedCity != null) {
      return 'No hay abogados de $_selectedSpecialty\nen $_selectedCity';
    } else if (_selectedSpecialty != null) {
      return 'No hay abogados especializados en $_selectedSpecialty';
    } else if (_selectedCity != null) {
      return 'No hay abogados en $_selectedCity';
    } else {
      return 'Intenta ajustar los filtros de búsqueda';
    }
  }

  Widget _buildLawyerCard(Lawyer lawyer, int ranking) {
    String? province = EcuadorCities.getProvinceOfCity(lawyer.city);
    String locationText = province != null ? '${lawyer.city}, $province' : lawyer.city;

    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
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
              // Ranking badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ranking <= 3 ? Colors.amber : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$ranking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              
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