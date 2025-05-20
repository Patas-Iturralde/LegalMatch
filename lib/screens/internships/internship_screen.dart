import 'package:abogados/services/auth_service.dart';
import 'package:abogados/services/lawyer_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/internship.dart';
import '../../services/internship_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternshipScreen extends StatefulWidget {
  final bool isLawyer;

  InternshipScreen({required this.isLawyer});

  @override
  _InternshipScreenState createState() => _InternshipScreenState();
}

class _InternshipScreenState extends State<InternshipScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  final InternshipService _internshipService = InternshipService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final AuthService _authService = AuthService();
  final LawyerService _lawyerService = LawyerService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showForm = false;

  List<Internship> _internships = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
  void _loadInternships() {
    _internshipService.getActiveInternships().listen((internships) {
      setState(() {
        _internships = internships;
      });
    });
  }

  Future<void> _applyForInternship(Internship internship) async {
  try {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes iniciar sesión para aplicar a esta vacante')),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    bool confirm = await _showApplyConfirmationDialog(internship.title);
    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    // Obtener información del perfil del usuario desde Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String userName = 'Usuario';
    String userEmail = user.email ?? '';
    
    // Si el documento del usuario existe, obtener el nombre
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['name'] ?? user.displayName ?? 'Usuario';
    } else {
      userName = user.displayName ?? 'Usuario';
    }

    // Verificar que tenemos email
    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener tu email. Por favor, actualiza tu perfil.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Aplicar a la vacante
    await _internshipService.applyForInternship(
      internshipId: internship.id,
      clientId: user.uid,
      clientName: userName, // Usar el nombre correcto
      clientEmail: userEmail,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Has aplicado exitosamente a esta vacante')),
    );
  } catch (e) {
    print('Error al aplicar a la vacante: $e');
    
    if (e.toString().contains('Ya has aplicado')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya has aplicado a esta vacante anteriormente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aplicar a la vacante: $e')),
      );
    }
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// Método auxiliar para mostrar diálogo de confirmación
Future<bool> _showApplyConfirmationDialog(String vacancyTitle) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Confirmar aplicación'),
        content: Text('¿Estás seguro de que quieres aplicar a la vacante "$vacancyTitle"? El abogado podrá ver tu nombre y correo electrónico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Aplicar'),
          ),
        ],
      );
    },
  ) ?? false; // Si el diálogo se cierra sin seleccionar, devuelve false
}

  Future<void> _submitInternship() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el usuario es un abogado
      final userType = await _authService.getUserType(user.uid);
      if (userType != UserType.lawyer) {
        throw Exception('Solo los abogados pueden publicar vacantes');
      }

      // Obtener datos del abogado para incluir el nombre
      final lawyer = await _lawyerService.getLawyerById(user.uid);
      if (lawyer == null) {
        throw Exception('No se encontraron datos del abogado');
      }

      final internship = Internship(
        id: '', // Se asignará en el servicio
        lawyerId: user.uid,
        lawyerName: lawyer.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _internshipService.createInternship(internship);

      // Limpiar el formulario después de enviar
      _titleController.clear();
      _descriptionController.clear();
      _requirementsController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vacante publicada con éxito')),
      );

      setState(() {
        _showForm = false;
      });
    } catch (e) {
      print('Error al publicar vacante: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar vacante: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> applyForInternship({
  required String internshipId,
  required String clientId,
  required String clientName,
  required String clientEmail,
}) async {
  // Verificar si ya ha aplicado
  QuerySnapshot existingApplications = await _firestore
      .collection('internship_applications')
      .where('internshipId', isEqualTo: internshipId)
      .where('clientId', isEqualTo: clientId)
      .get();

  if (existingApplications.docs.isNotEmpty) {
    throw Exception('Ya has aplicado a esta vacante');
  }

  // Crear nueva aplicación
  await _firestore.collection('internship_applications').add({
    'internshipId': internshipId,
    'clientId': clientId,
    'clientName': clientName,
    'clientEmail': clientEmail,
    'appliedAt': Timestamp.now(),
    'status': 'pending',
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vacantes para Pasantes'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Formulario para publicar vacante (solo para abogados)
                if (widget.isLawyer && _showForm) _buildInternshipForm(),

                // Lista de vacantes
                Expanded(
                  child: StreamBuilder<List<Internship>>(
                    stream: _internshipService.getActiveInternships(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final internships = snapshot.data ?? [];

                      if (internships.isEmpty) {
                        return Center(
                          child:
                              Text('No hay vacantes disponibles actualmente'),
                        );
                      }

                      return ListView.builder(
                        itemCount: internships.length,
                        itemBuilder: (context, index) {
                          return _buildInternshipCard(internships[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: widget.isLawyer
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showForm = !_showForm;
                });
              },
              child: Icon(_showForm ? Icons.close : Icons.add),
            )
          : null,
    );
  }

  Widget _buildInternshipForm() {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Publicar Nueva Vacante',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Requisitos
              TextFormField(
                controller: _requirementsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Requisitos',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa los requisitos';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Botón publicar
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInternship,
                child: _isSubmitting
                    ? SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.0,
                        ),
                      )
                    : Text('Publicar Vacante'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternshipCard(Internship internship) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final user = Provider.of<User?>(context);
    final bool isMyInternship = user?.uid == internship.lawyerId;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    internship.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(internship.createdAt),
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),

            // Publicado por
            Row(
              children: [
                Icon(Icons.person, size: 16.0, color: Colors.grey[600]),
                SizedBox(width: 4.0),
                Text(
                  'Publicado por: ${internship.lawyerName}',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // Descripción
            Text(
              'Descripción:',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.0),
            Text(internship.description),
            SizedBox(height: 16.0),

            // Requisitos
            Text(
              'Requisitos:',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.0),
            Text(internship.requirements),
            SizedBox(height: 16.0),

            // Botón para aplicar (solo para clientes)
            if (!widget.isLawyer && user != null)
              ElevatedButton(
                onPressed: () => _applyForInternship(internship),
                child: Text('Aplicar a esta vacante'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.0),
                ),
              ),

            // Opciones para el abogado que publicó la vacante
            if (isMyInternship)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.people),
                    label: Text('Ver Aplicantes'),
                    onPressed: () {
                      // Implementar visualización de aplicantes
                      _showApplicantsDialog(context, internship);
                    },
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label:
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      // Confirmar eliminación
                      _showDeleteConfirmationDialog(context, internship.id);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApplicantsDialog(BuildContext context, Internship internship) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Aplicantes para ${internship.title}'),
        content: Container(
          width: double.maxFinite,
          child: StreamBuilder<List<InternshipApplication>>(
            stream: _internshipService.getInternshipApplications(internship.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final applications = snapshot.data ?? [];

              if (applications.isEmpty) {
                return Text('Aún no hay aplicantes para esta vacante.');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final application = applications[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información del aplicante
                          Row(
                            children: [
                              Icon(Icons.person, color: Theme.of(context).primaryColor),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      application.clientName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      application.clientEmail,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.0),
                          
                          // Fecha de aplicación
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16.0, color: Colors.grey[600]),
                              SizedBox(width: 8.0),
                              Text(
                                'Aplicó el ${DateFormat('dd/MM/yyyy, HH:mm').format(application.appliedAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.0),
                          
                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Botón para enviar correo
                              ElevatedButton.icon(
                                icon: Icon(Icons.email, size: 16.0),
                                label: Text('Contactar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _contactApplicant(application),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

Future<void> _contactApplicant(InternshipApplication application) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: application.clientEmail,
    queryParameters: {
      'subject': 'Respuesta a tu aplicación para "${_getInternshipTitle(application.internshipId)}"',
      'body': 'Hola ${application.clientName},\n\nGracias por tu interés en la posición de pasante en nuestra firma. Estamos revisando tu aplicación y nos gustaría...\n\nSaludos cordiales,\n[Tu nombre]'
    },
  );
  
  try {
    final canLaunch = await canLaunchUrl(emailLaunchUri);
    if (canLaunch) {
      await launchUrl(emailLaunchUri);
    } else {
      // Si no se puede abrir la aplicación de correo, mostrar el correo para copiar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir la aplicación de correo. Correo del aplicante: ${application.clientEmail}'),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: application.clientEmail));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Correo copiado al portapapeles')),
              );
            },
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }
  } catch (e) {
    print('Error al intentar enviar correo: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al intentar contactar: $e')),
    );
  }
}

// Método auxiliar para obtener el título de la vacante
String _getInternshipTitle(String internshipId) {
  final internship = _internships.firstWhere(
    (i) => i.id == internshipId,
    orElse: () => Internship(
      id: '',
      lawyerId: '',
      lawyerName: '',
      title: 'Vacante',
      description: '',
      requirements: '',
      createdAt: DateTime.now(),
      isActive: true,
    ),
  );
  
  return internship.title;
}

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String internshipId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar vacante'),
          content: Text(
              '¿Estás seguro de que deseas eliminar esta vacante? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _internshipService.deleteInternship(internshipId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vacante eliminada con éxito')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar vacante')),
                  );
                }
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
