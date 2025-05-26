import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/forum.dart';
import '../../services/forum_service.dart';
import '../../services/auth_service.dart';

// Pantalla para crear un nuevo tema
class CreateTopicScreen extends StatefulWidget {
  final String? categoryId;

  CreateTopicScreen({this.categoryId});

  @override
  _CreateTopicScreenState createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends State<CreateTopicScreen> {
  final ForumService _forumService = ForumService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String? _selectedCategoryId;
  bool _isLoading = false;
  List<ForumCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    _forumService.getCategories().listen((categories) {
      setState(() {
        _categories = categories;
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    });
  }

  Future<void> _createTopic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) throw Exception('Usuario no autenticado');

      final userType = await _authService.getUserType(user.uid);
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _forumService.createTopic(
        categoryId: _selectedCategoryId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Usuario',
        isLawyer: userType == UserType.lawyer,
        tags: tags,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tema creado exitosamente')),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Nuevo Tema'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTopic,
            child: Text(
              'PUBLICAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categoría
              Text(
                'Categoría',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una categoría';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              
              // Título
              Text(
                'Título',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escribe un título descriptivo...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  if (value.trim().length < 10) {
                    return 'El título debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              
              // Contenido
              Text(
                'Contenido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe tu consulta o tema de discusión...',
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el contenido';
                  }
                  if (value.trim().length < 20) {
                    return 'El contenido debe tener al menos 20 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              
              // Tags
              Text(
                'Etiquetas (opcional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'divorcio, custodia, pensión... (separadas por comas)',
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Las etiquetas ayudan a otros usuarios a encontrar tu tema',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 32.0),
              
              // Botón crear
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTopic,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Crear Tema'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}