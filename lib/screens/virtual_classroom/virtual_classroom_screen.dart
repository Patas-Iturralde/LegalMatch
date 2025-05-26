import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/virtual_classroom.dart';
import '../../services/virtual_classroom_service.dart';
import '../../services/auth_service.dart';

class VirtualClassroomScreen extends StatefulWidget {
  final bool isLawyer;

  VirtualClassroomScreen({required this.isLawyer});

  @override
  _VirtualClassroomScreenState createState() => _VirtualClassroomScreenState();
}

class _VirtualClassroomScreenState extends State<VirtualClassroomScreen> with SingleTickerProviderStateMixin {
  final VirtualClassroomService _classroomService = VirtualClassroomService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _categoryController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCreateForm = false;
  String _selectedType = 'link';
  String _selectedCategory = 'General';
  
  final List<String> _resourceTypes = [
    'link',
    'document',
    'video',
    'form',
  ];
  
  final List<String> _categories = [
    'General',
    'Derecho Civil',
    'Derecho Penal',
    'Derecho Laboral',
    'Derecho Familiar',
    'Derecho Mercantil',
    'Formularios',
    'Plantillas',
    'Recursos Educativos',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _createResource() async {
    if (_titleController.text.trim().isEmpty || 
        _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor complete los campos obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) throw Exception('Usuario no autenticado');

      await _classroomService.createResource(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        url: _urlController.text.trim(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Usuario',
        category: _selectedCategory,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recurso creado exitosamente')),
      );

      _titleController.clear();
      _descriptionController.clear();
      _urlController.clear();
      
      setState(() {
        _showCreateForm = false;
      });

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
        title: Text('Aula Virtual'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Formulario para crear nuevo recurso (solo abogados)
          if (widget.isLawyer && _showCreateForm) _buildCreateForm(),
          
          // Lista de recursos por categoría
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) => _buildResourcesList(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isLawyer
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showCreateForm = !_showCreateForm;
                });
              },
              child: Icon(_showCreateForm ? Icons.close : Icons.add),
              tooltip: 'Agregar recurso',
            )
          : null,
    );
  }

  Widget _buildCreateForm() {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar Nuevo Recurso',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            
            // Tipo de recurso
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tipo de recurso',
                border: OutlineInputBorder(),
              ),
              items: _resourceTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            SizedBox(height: 12.0),
            
            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: 12.0),
            
            // Título
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12.0),
            
            // URL
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL/Enlace *',
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 12.0),
            
            // Descripción
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.0),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createResource,
                    child: _isLoading
                        ? SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                        : Text('Crear Recurso'),
                  ),
                ),
                SizedBox(width: 12.0),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showCreateForm = false;
                    });
                  },
                  child: Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesList(String category) {
    return StreamBuilder<List<VirtualResource>>(
      stream: _classroomService.getResourcesByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final resources = snapshot.data ?? [];

        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay recursos en esta categoría',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                if (widget.isLawyer) ...[
                  SizedBox(height: 8),
                  Text(
                    'Agrega el primer recurso',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: resources.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            return _buildResourceCard(resources[index]);
          },
        );
      },
    );
  }

  Widget _buildResourceCard(VirtualResource resource) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _openResource(resource),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: _getTypeColor(resource.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getTypeIcon(resource.type),
                      color: _getTypeColor(resource.type),
                      size: 24.0,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          _getTypeDisplayName(resource.type),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: _getTypeColor(resource.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleResourceAction(value, resource),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 18),
                            SizedBox(width: 8),
                            Text('Abrir'),
                          ],
                        ),
                      ),
                      if (widget.isLawyer && resource.authorId == Provider.of<User?>(context)?.uid)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              if (resource.description.isNotEmpty) ...[
                SizedBox(height: 12.0),
                Text(
                  resource.description,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              SizedBox(height: 12.0),
              
              Row(
                children: [
                  Icon(Icons.person, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text(
                    resource.authorName,
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                  Spacer(),
                  Icon(Icons.visibility, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text(
                    '${resource.views}',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 12.0),
                  Icon(Icons.favorite, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text(
                    '${resource.likes}',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              SizedBox(height: 8.0),
              
              Text(
                'Publicado: ${DateFormat('dd/MM/yyyy').format(resource.createdAt)}',
                style: TextStyle(fontSize: 10.0, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleResourceAction(String action, VirtualResource resource) {
    switch (action) {
      case 'open':
        _openResource(resource);
        break;
      case 'delete':
        _deleteResource(resource);
        break;
    }
  }

  Future<void> _openResource(VirtualResource resource) async {
    try {
      // Incrementar contador de vistas
      await _classroomService.incrementViews(resource.id);
      
      final Uri url = Uri.parse(resource.url);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el recurso: $e')),
      );
    }
  }

  void _deleteResource(VirtualResource resource) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar Recurso'),
          content: Text('¿Está seguro de que desea eliminar "${resource.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _classroomService.deleteResource(resource.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recurso eliminado')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'link':
        return 'Enlace';
      case 'document':
        return 'Documento';
      case 'video':
        return 'Video';
      case 'form':
        return 'Formulario';
      default:
        return 'Recurso';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'link':
        return Icons.link;
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.play_circle;
      case 'form':
        return Icons.assignment;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'link':
        return Colors.blue;
      case 'document':
        return Colors.red;
      case 'video':
        return Colors.green;
      case 'form':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}