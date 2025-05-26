import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/mediation.dart';
import '../../models/lawyer.dart';
import '../../services/mediation_service.dart';
import '../../services/lawyer_service.dart';
import '../../services/auth_service.dart';
import 'dart:convert';

class MediationScreen extends StatefulWidget {
  final bool isLawyer;

  MediationScreen({required this.isLawyer});

  @override
  _MediationScreenState createState() => _MediationScreenState();
}

class _MediationScreenState extends State<MediationScreen> with SingleTickerProviderStateMixin {
  final MediationService _mediationService = MediationService();
  final LawyerService _lawyerService = LawyerService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCreateForm = false;
  
  // Para la selección de abogados
  List<Lawyer> _availableLawyers = [];
  Lawyer? _selectedLawyer;
  bool _isLoadingLawyers = false;
  String _lawyerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!widget.isLawyer) {
      _loadAvailableLawyers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableLawyers() async {
    setState(() {
      _isLoadingLawyers = true;
    });

    try {
      _lawyerService.getLawyers().listen((lawyers) {
        setState(() {
          _availableLawyers = lawyers;
          _isLoadingLawyers = false;
        });
      });
    } catch (e) {
      print('Error al cargar abogados: $e');
      setState(() {
        _isLoadingLawyers = false;
      });
    }
  }

  List<Lawyer> _getFilteredLawyers() {
    if (_lawyerSearchQuery.isEmpty) {
      return _availableLawyers;
    }
    
    return _availableLawyers.where((lawyer) {
      final query = _lawyerSearchQuery.toLowerCase();
      return lawyer.name.toLowerCase().contains(query) ||
             lawyer.specialties.any((specialty) => specialty.toLowerCase().contains(query)) ||
             lawyer.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _createMediationCase() async {
    if (_titleController.text.trim().isEmpty || 
        _descriptionController.text.trim().isEmpty ||
        _selectedLawyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) throw Exception('Usuario no autenticado');

      await _mediationService.createMediationCase(
        clientId: user.uid,
        clientName: user.displayName ?? 'Cliente',
        lawyerEmail: _selectedLawyer!.email,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud de mediación creada exitosamente')),
      );

      _titleController.clear();
      _descriptionController.clear();
      _selectedLawyer = null;
      
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
        title: Text('Mediación'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Activos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Resueltos'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Formulario para crear nueva mediación (solo clientes)
          if (!widget.isLawyer && _showCreateForm) _buildCreateForm(),
          
          // Lista de casos de mediación
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCasesList('active'),
                _buildCasesList('pending'),
                _buildCasesList('resolved'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !widget.isLawyer
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showCreateForm = !_showCreateForm;
                });
              },
              child: Icon(_showCreateForm ? Icons.close : Icons.add),
              tooltip: 'Solicitar mediación',
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
              'Solicitar Mediación',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del caso',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            
            // Selector de abogado mejorado
            Text(
              'Seleccionar Abogado',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.0),
            
            if (_isLoadingLawyers)
              Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Cargando abogados disponibles...'),
                  ],
                ),
              )
            else
              _buildLawyerSelector(),
            
            SizedBox(height: 16.0),
            
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción del conflicto',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16.0),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createMediationCase,
                    child: _isLoading
                        ? SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                        : Text('Solicitar Mediación'),
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

  Widget _buildLawyerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, especialidad o email...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: Icon(Icons.search),
            suffixIcon: _lawyerSearchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _lawyerSearchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _lawyerSearchQuery = value;
            });
          },
        ),
        SizedBox(height: 12.0),
        
        // Abogado seleccionado
        if (_selectedLawyer != null)
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  backgroundImage: _selectedLawyer!.photoBase64.isNotEmpty
                      ? MemoryImage(base64Decode(_selectedLawyer!.photoBase64))
                      : null,
                  child: _selectedLawyer!.photoBase64.isEmpty
                      ? Icon(Icons.person, color: Colors.blue)
                      : null,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLawyer!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _selectedLawyer!.specialties.join(', '),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 2),
                          Text(
                            '${_selectedLawyer!.rating.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '\${_selectedLawyer!.consultationPrice}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedLawyer = null;
                    });
                  },
                ),
              ],
            ),
          )
        else
          // Lista de abogados disponibles
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: _getFilteredLawyers().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          _lawyerSearchQuery.isEmpty
                              ? 'No hay abogados disponibles'
                              : 'No se encontraron abogados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _getFilteredLawyers().length,
                    itemBuilder: (context, index) {
                      final lawyer = _getFilteredLawyers()[index];
                      return _buildLawyerItem(lawyer);
                    },
                  ),
          ),
        
        if (_selectedLawyer == null)
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Selecciona un abogado de la lista para continuar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLawyerItem(Lawyer lawyer) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLawyer = lawyer;
          _lawyerSearchQuery = '';
        });
      },
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: lawyer.photoBase64.isNotEmpty
                  ? MemoryImage(base64Decode(lawyer.photoBase64))
                  : null,
              child: lawyer.photoBase64.isEmpty
                  ? Icon(Icons.person, size: 20, color: Colors.grey[600])
                  : null,
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lawyer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (lawyer.specialties.isNotEmpty)
                    Text(
                      lawyer.specialties.take(2).join(', '),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        lawyer.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 10),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '\${lawyer.consultationPrice}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesList(String status) {
    final user = Provider.of<User?>(context);
    if (user == null) return Center(child: Text('Usuario no autenticado'));

    return StreamBuilder<List<MediationCase>>(
      stream: widget.isLawyer
          ? _mediationService.getLawyerMediationCases(user.uid, status)
          : _mediationService.getClientMediationCases(user.uid, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final cases = snapshot.data ?? [];

        if (cases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay casos de mediación ${_getStatusText(status).toLowerCase()}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: cases.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            return _buildCaseCard(cases[index]);
          },
        );
      },
    );
  }

  Widget _buildCaseCard(MediationCase mediationCase) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _openCaseDetail(mediationCase),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mediationCase.title,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(mediationCase.status),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _getStatusText(mediationCase.status),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              
              Text(
                mediationCase.description,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.0),
              
              Row(
                children: [
                  Icon(Icons.person, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text(
                    'Cliente: ${mediationCase.clientName}',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 4.0),
              
              if (mediationCase.lawyerName.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.business, size: 16.0, color: Colors.grey[600]),
                    SizedBox(width: 4.0),
                    Text(
                      'Abogado: ${mediationCase.lawyerName}',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                    ),
                  ],
                ),
              
              SizedBox(height: 8.0),
              
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text(
                    'Creado: ${DateFormat('dd/MM/yyyy').format(mediationCase.createdAt)}',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                  Spacer(),
                  if (mediationCase.scheduledAt != null)
                    Text(
                      'Programado: ${DateFormat('dd/MM/yyyy HH:mm').format(mediationCase.scheduledAt!)}',
                      style: TextStyle(fontSize: 12.0, color: Colors.blue[700]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCaseDetail(MediationCase mediationCase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediationDetailScreen(
          mediationCase: mediationCase,
          isLawyer: widget.isLawyer,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'active':
        return 'Activo';
      case 'resolved':
        return 'Resuelto';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class MediationDetailScreen extends StatefulWidget {
  final MediationCase mediationCase;
  final bool isLawyer;

  MediationDetailScreen({
    required this.mediationCase,
    required this.isLawyer,
  });

  @override
  _MediationDetailScreenState createState() => _MediationDetailScreenState();
}

class _MediationDetailScreenState extends State<MediationDetailScreen> {
  final MediationService _mediationService = MediationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) return;

      await _mediationService.sendMessage(
        caseId: widget.mediationCase.id,
        senderId: user.uid,
        senderName: user.displayName ?? 'Usuario',
        senderType: widget.isLawyer ? 'lawyer' : 'client',
        message: message,
      );

      _messageController.clear();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mediationCase.title),
        actions: [
          if (widget.mediationCase.status == 'active')
            IconButton(
              icon: Icon(Icons.check_circle),
              onPressed: _resolveCase,
              tooltip: 'Marcar como resuelto',
            ),
        ],
      ),
      body: Column(
        children: [
          // Case info header
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mediationCase.description,
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.mediationCase.status),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        _getStatusText(widget.mediationCase.status),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: StreamBuilder<List<MediationMessage>>(
              stream: _mediationService.getCaseMessages(widget.mediationCase.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text('No hay mensajes aún. ¡Inicia la conversación!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          
          // Message input
          if (widget.mediationCase.status == 'active')
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: Icon(Icons.send),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MediationMessage message) {
    final user = Provider.of<User?>(context);
    final isCurrentUser = message.senderId == user?.uid;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 12.0,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Theme.of(context).primaryColor
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                      color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 4.0),
                  if (message.senderType == 'lawyer')
                    Icon(
                      Icons.verified,
                      size: 12.0,
                      color: isCurrentUser ? Colors.white70 : Colors.blue,
                    ),
                  Spacer(),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.0),
              Text(
                message.message,
                style: TextStyle(
                  fontSize: 15.0,
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resolveCase() {
    showDialog(
      context: context,
      builder: (context) {
        final resolutionController = TextEditingController();
        
        return AlertDialog(
          title: Text('Resolver Caso de Mediación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Está seguro de que desea marcar este caso como resuelto?'),
              SizedBox(height: 16.0),
              TextField(
                controller: resolutionController,
                decoration: InputDecoration(
                  labelText: 'Resolución (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _mediationService.resolveCase(
                    widget.mediationCase.id,
                    resolutionController.text.trim(),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Caso marcado como resuelto')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Resolver'),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'active':
        return 'Activo';
      case 'resolved':
        return 'Resuelto';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}