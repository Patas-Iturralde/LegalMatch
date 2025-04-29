import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/lawyer.dart';
import '../../services/lawyer_service.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'dart:io';

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
  final _specialtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController(); // Nuevo controlador para teléfono
  
  bool _isLoading = true;
  bool _isSaving = false;
  Lawyer? _lawyerData;
  String? _photoBase64;
  List<String> _availableSpecialties = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.isLawyer) {
      _loadSpecialties();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose(); // Liberar el controlador de teléfono
    super.dispose();
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
            _specialtyController.text = lawyer.specialty;
            _priceController.text = lawyer.consultationPrice.toString();
            _descriptionController.text = lawyer.description;
            _phoneController.text = lawyer.phone ?? ''; // Inicializar controlador de teléfono
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
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        
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
          specialty: _specialtyController.text.trim(),
          photoBase64: _photoBase64 ?? '',
          consultationPrice: double.tryParse(_priceController.text) ?? 0.0,
          email: _lawyerData!.email,
          description: _descriptionController.text.trim(),
          rating: _lawyerData!.rating,
          reviewCount: _lawyerData!.reviewCount,
          phone: _phoneController.text.trim(), // Guardar el teléfono
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
              child: widget.isLawyer
                  ? _buildLawyerProfile(user)
                  : _buildClientProfile(user),
            ),
    );
  }

  Widget _buildLawyerProfile(User user) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de perfil
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120.0,
                  height: 120.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
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
            initialValue: user.email,
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              filled: true,
              fillColor: Colors.grey[200],
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
              hintText: 'Ej. 5219871234567', // Formato internacional recomendado
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un número de teléfono';
              }
              // Validación simple: solo números
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Solo debe contener números, sin espacios ni caracteres especiales';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          
          // Especialidad (dropdown)
          DropdownButtonFormField<String>(
            value: _specialtyController.text.isNotEmpty ? _specialtyController.text : null,
            decoration: InputDecoration(
              labelText: 'Especialidad',
              prefixIcon: Icon(Icons.work),
            ),
            items: _availableSpecialties.map((specialty) {
              return DropdownMenuItem<String>(
                value: specialty,
                child: Text(specialty),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _specialtyController.text = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona una especialidad';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          
          // Precio de consulta
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Precio de consulta (\$)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un precio';
              }
              if (double.tryParse(value) == null) {
                return 'Ingresa un número válido';
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
              labelText: 'Descripción profesional',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una descripción';
              }
              return null;
            },
          ),
          SizedBox(height: 24.0),
          
          // Botón guardar
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    height: 20.0,
                    width: 20.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  )
                : Text('Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientProfile(User user) {
    // [El código de la función _buildClientProfile permanece igual]
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen de perfil
        Center(
          child: Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: Icon(Icons.person, size: 60.0, color: Colors.grey[600]),
          ),
        ),
        SizedBox(height: 24.0),
        
        // Datos del cliente
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
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.0),
                
                // Email
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text(user.email ?? 'No disponible'),
                ),
                
                // Tipo de usuario
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
        
        // Configuración de cuenta
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
                
                // Cambiar contraseña
                ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Cambiar contraseña'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    // Implementar cambio de contraseña
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Funcionalidad en desarrollo')),
                    );
                  },
                ),
                
                // Editar perfil
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar perfil'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    // Implementar edición de perfil
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
}