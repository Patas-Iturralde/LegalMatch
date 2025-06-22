import 'package:abogados/utils/web_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/lawyer.dart';
import '../../services/lawyer_service.dart';
import '../../services/auth_service.dart';
import '../../utils/ecuador_cities.dart'; // Importar las ciudades
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final bool isLawyer;

  ProfileScreen({required this.isLawyer});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LawyerService _lawyerService = LawyerService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos del formulario
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Lista de especialidades seleccionadas
  List<String> _selectedSpecialties = [];
  String _selectedCity = 'Quito'; // Ciudad por defecto
  
  bool _isLoading = true;
  bool _isSaving = false;
  Lawyer? _lawyerData;
  String? _photoBase64;
  List<String> _availableSpecialties = [];
  List<String> _allCities = [];
  List<String> _filteredCities = [];
  final _citySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadUserData();
    if (widget.isLawyer) {
      _loadSpecialties();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  // Cargar las ciudades del Ecuador
  void _loadCities() {
    _allCities = EcuadorCities.getAllCities();
    _filteredCities = _allCities;
  }

  // Filtrar ciudades basado en la búsqueda
  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _allCities;
      } else {
        _filteredCities = EcuadorCities.searchCities(query);
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user != null && widget.isLawyer) {
        final lawyer = await _lawyerService.getLawyerById(user.uid);
        if (lawyer != null) {
          setState(() {
            _lawyerData = lawyer;
            _nameController.text = lawyer.name;
            _selectedSpecialties = List<String>.from(lawyer.specialties);
            _selectedCity = lawyer.city.isNotEmpty ? lawyer.city : 'Quito';
            _priceController.text = lawyer.consultationPrice.toString();
            _descriptionController.text = lawyer.description;
            _phoneController.text = lawyer.phone ?? '';
            _photoBase64 = lawyer.photoBase64;
          });
        }
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSpecialties() async {
    try {
      final specialties = await _lawyerService.getSpecialties();
      setState(() {
        _availableSpecialties = specialties;
      });
    } catch (e) {
      print('Error al cargar especialidades: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final base64Image = await WebImagePicker.pickImage();
      
      if (base64Image != null) {
        setState(() {
          _photoBase64 = base64Image;
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user != null && widget.isLawyer && _lawyerData != null) {
        final updatedLawyer = Lawyer(
          id: user.uid,
          name: _nameController.text.trim(),
          specialties: _selectedSpecialties,
          city: _selectedCity, // Incluir la ciudad seleccionada
          photoBase64: _photoBase64 ?? '',
          consultationPrice: double.tryParse(_priceController.text) ?? 0.0,
          email: _lawyerData!.email,
          description: _descriptionController.text.trim(),
          rating: _lawyerData!.rating,
          reviewCount: _lawyerData!.reviewCount,
          phone: _phoneController.text.trim(),
        );
        
        await _lawyerService.updateLawyerProfile(updatedLawyer);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil actualizado con éxito')),
        );
      }
    } catch (e) {
      print('Error al guardar perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar perfil')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildLawyerProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Foto de perfil
        Center(
          child: Stack(
            children: [
              Container(
                width: 120.0,
                height: 120.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: _photoBase64 != null && _photoBase64!.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(_photoBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _photoBase64 == null || _photoBase64!.isEmpty
                    ? Icon(Icons.person, size: 60.0, color: Colors.grey[600])
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.0),
        
        // Formulario para datos del abogado
        Text(
          'Información Personal',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        
        // Nombre
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),
        
        // Email (no editable)
        TextFormField(
          initialValue: _lawyerData?.email ?? '',
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 16.0),
        
        // Teléfono para WhatsApp
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Teléfono para WhatsApp',
            prefixIcon: Icon(Icons.phone),
            hintText: 'Ej. 0987654321',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 16.0),

        // Selector de ciudad con búsqueda
        Text(
          'Ciudad donde atiende',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.0),
        
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'Seleccionar ciudad',
            prefixIcon: Icon(Icons.location_city),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _allCities.map((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(
                city,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCity = newValue ?? 'Quito';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona una ciudad';
            }
            return null;
          },
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down),
          // Mostrar provincia entre paréntesis
          selectedItemBuilder: (BuildContext context) {
            return _allCities.map<Widget>((String city) {
              String? province = EcuadorCities.getProvinceOfCity(city);
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  province != null ? '$city ($province)' : city,
                  style: TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
        ),
        SizedBox(height: 16.0),

        // Información profesional
        Text(
          'Información Profesional',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        
        // Especialidades
        Text(
          'Especialidades',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.0),
        
        // Lista de especialidades con chips
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _availableSpecialties.map((specialty) {
            bool isSelected = _selectedSpecialties.contains(specialty);
            return FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecialties.add(specialty);
                  } else {
                    _selectedSpecialties.remove(specialty);
                  }
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        SizedBox(height: 16.0),
        
        // Precio de consulta
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Precio de consulta (USD)',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el precio';
            }
            if (double.tryParse(value) == null) {
              return 'Ingresa un precio válido';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),
        
        // Descripción
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Descripción de servicios',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa una descripción';
            }
            return null;
          },
        ),
        SizedBox(height: 32.0),
        
        // Botón guardar
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Guardar Perfil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildClientProfile() {
    return Column(
      children: [
        Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40.0,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 40.0, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.0),
                
                Text(
                  Provider.of<User?>(context)?.displayName ?? 'Usuario',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),
                
                Text(
                  Provider.of<User?>(context)?.email ?? 'No disponible',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
                
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Tipo de usuario'),
                  subtitle: Text('Cliente'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.0),
        
        Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Cuenta',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.0),
                
                ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Cambiar contraseña'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Funcionalidad en desarrollo')),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar perfil'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Funcionalidad en desarrollo')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    if (user == null) {
      return Center(
        child: Text('No hay sesión activa'),
      );
    }

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: widget.isLawyer
                    ? _buildLawyerProfile()
                    : _buildClientProfile(),
              ),
            ),
    );
  }
}