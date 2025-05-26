import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/alternative_resolution.dart';
import '../../models/lawyer.dart';
import '../../services/alternative_resolution_service.dart';
import '../../services/lawyer_service.dart';
import '../../services/auth_service.dart';
import 'resolution_case_detail_screen.dart';
import 'dart:convert';

class AlternativeResolutionScreen extends StatefulWidget {
  final bool isLawyer;

  AlternativeResolutionScreen({required this.isLawyer});

  @override
  _AlternativeResolutionScreenState createState() => _AlternativeResolutionScreenState();
}

class _AlternativeResolutionScreenState extends State<AlternativeResolutionScreen> 
    with SingleTickerProviderStateMixin {
  final AlternativeResolutionService _resolutionService = AlternativeResolutionService();
  final LawyerService _lawyerService = LawyerService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  bool _showCreateForm = false;
  Map<String, int> _statistics = {};

  bool _isInfoHeaderExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final stats = await _resolutionService.getStatistics(user.uid, widget.isLawyer);
      setState(() {
        _statistics = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medios Alternativos de Resolución'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Activos'),
                  if (_statistics['active'] != null && _statistics['active']! > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_statistics['active']}',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            Tab(text: 'Resueltos'),
            Tab(text: 'Estadísticas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Encabezado informativo
          _buildInfoHeader(),
          
          // Formulario de creación (solo clientes)
          if (!widget.isLawyer && _showCreateForm) 
            Expanded(child: CreateResolutionCaseForm()),
          
          // Contenido de pestañas
          if (!_showCreateForm)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCasesList('active'),
                  _buildCasesList('resolved'),
                  _buildStatisticsTab(),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: !widget.isLawyer
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showCreateForm = !_showCreateForm;
                });
              },
              icon: Icon(_showCreateForm ? Icons.close : Icons.add),
              label: Text(_showCreateForm ? 'Cancelar' : 'Nuevo Caso'),
              backgroundColor: _showCreateForm ? Colors.red : Colors.blue,
            )
          : null,
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          // Header siempre visible con botón para colapsar/expandir
          InkWell(
            onTap: () {
              setState(() {
                _isInfoHeaderExpanded = !_isInfoHeaderExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.balance, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medios Alternativos de Resolución',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isInfoHeaderExpanded) // Solo mostrar cuando está colapsado
                          Text(
                            'Toca para ver más información',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isInfoHeaderExpanded ? 0.5 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido expandible
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(), // Estado colapsado
            secondChild: Container(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resuelve tus conflictos de manera eficiente a través de mediación o arbitraje.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickStat('⚖️', 'Mediación', 'Colaborativo'),
                      SizedBox(width: 20),
                      _buildQuickStat('🏛️', 'Arbitraje', 'Vinculante'),
                    ],
                  ),
                ],
              ),
            ), // Estado expandido
            crossFadeState: _isInfoHeaderExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Método _buildQuickStat permanece igual
  Widget _buildQuickStat(String emoji, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCasesList(String status) {
    final user = Provider.of<User?>(context);
    if (user == null) return Center(child: Text('Usuario no autenticado'));

    return StreamBuilder<List<AlternativeResolutionCase>>(
      stream: widget.isLawyer
          ? _resolutionService.getLawyerCases(user.uid, status)
          : _resolutionService.getClientCases(user.uid, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final cases = snapshot.data ?? [];

        if (cases.isEmpty) {
          return _buildEmptyState(status);
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

  Widget _buildEmptyState(String status) {
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case 'active':
        icon = Icons.forum;
        title = 'No hay casos activos';
        subtitle = widget.isLawyer 
            ? 'Los clientes pueden iniciar nuevos casos de resolución'
            : 'Inicia un nuevo caso de mediación o arbitraje';
        break;
      case 'resolved':
        icon = Icons.check_circle;
        title = 'No hay casos resueltos';
        subtitle = 'Los casos resueltos aparecerán aquí';
        break;
      default:
        icon = Icons.inbox;
        title = 'No hay casos';
        subtitle = 'Los casos aparecerán aquí';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(AlternativeResolutionCase resolutionCase) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _openCaseDetail(resolutionCase),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: resolutionCase.type == ResolutionType.mediation 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: resolutionCase.type == ResolutionType.mediation 
                            ? Colors.green 
                            : Colors.blue,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          resolutionCase.type == ResolutionType.mediation 
                              ? Icons.handshake 
                              : Icons.gavel,
                          size: 14,
                          color: resolutionCase.type == ResolutionType.mediation 
                              ? Colors.green[700] 
                              : Colors.blue[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          resolutionCase.typeDisplayName,
                          style: TextStyle(
                            color: resolutionCase.type == ResolutionType.mediation 
                                ? Colors.green[700] 
                                : Colors.blue[700],
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(resolutionCase.status),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _getStatusText(resolutionCase.status),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.0),
              
              Text(
                resolutionCase.title,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              
              Text(
                resolutionCase.description,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.0),
              
              if (resolutionCase.amount != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.orange[700]),
                      SizedBox(width: 4),
                      Text(
                        'Monto: \$${resolutionCase.amount!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(height: 20),
              
              Row(
                children: [
                  Icon(Icons.person, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      widget.isLawyer 
                          ? 'Cliente: ${resolutionCase.clientName}'
                          : 'Abogado: ${resolutionCase.lawyerName}',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text(
                    DateFormat('dd/MM/yyyy').format(resolutionCase.createdAt),
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                ],
              ),

              if (resolutionCase.scheduledAt != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Sesión programada: ${DateFormat('dd/MM/yyyy HH:mm').format(resolutionCase.scheduledAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas de Casos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Casos Activos',
                  _statistics['active']?.toString() ?? '0',
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Casos Resueltos',
                  _statistics['resolved']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Mediaciones',
                  _statistics['mediation']?.toString() ?? '0',
                  Icons.handshake,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Arbitrajes',
                  _statistics['arbitration']?.toString() ?? '0',
                  Icons.gavel,
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información sobre MARC',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  
                  _buildInfoTile(
                    Icons.handshake,
                    'Mediación',
                    'Proceso colaborativo donde un mediador neutral facilita el diálogo entre las partes para alcanzar un acuerdo mutuamente beneficioso.',
                    Colors.green,
                  ),
                  
                  Divider(height: 24),
                  
                  _buildInfoTile(
                    Icons.gavel,
                    'Arbitraje',
                    'Proceso donde un árbitro imparcial escucha a ambas partes y emite una decisión vinculante basada en los hechos y argumentos presentados.',
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openCaseDetail(AlternativeResolutionCase resolutionCase) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ResolutionCaseDetailScreen(
        resolutionCase: resolutionCase, // ✅ Corregido
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

// Widget para crear nuevo caso
// Widget para crear nuevo caso - CORREGIDO
class CreateResolutionCaseForm extends StatefulWidget {
  @override
  _CreateResolutionCaseFormState createState() => _CreateResolutionCaseFormState();
}

class _CreateResolutionCaseFormState extends State<CreateResolutionCaseForm> {
  final AlternativeResolutionService _resolutionService = AlternativeResolutionService();
  final LawyerService _lawyerService = LawyerService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  ResolutionType _selectedType = ResolutionType.mediation;
  List<Lawyer> _availableLawyers = [];
  Lawyer? _selectedLawyer;
  bool _isLoading = false;
  bool _isLoadingLawyers = false;
  String _lawyerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableLawyers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
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

  // MÉTODO CORREGIDO PARA OBTENER EL NOMBRE REAL DEL CLIENTE
  Future<String> _getClientName(User user) async {
    try {
      // Primero intentar obtener desde la colección users
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        String userName = userData['name'];
        if (userName.isNotEmpty) {
          return userName;
        }
      }
      
      // Si no existe en users, usar displayName o email como fallback
      return user.displayName ?? user.email?.split('@')[0] ?? 'Cliente';
    } catch (e) {
      print('Error al obtener nombre del cliente: $e');
      return user.displayName ?? user.email?.split('@')[0] ?? 'Cliente';
    }
  }

  Future<void> _createCase() async {
    if (!_formKey.currentState!.validate() || _selectedLawyer == null) {
      if (_selectedLawyer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor selecciona un abogado')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) throw Exception('Usuario no autenticado');

      // OBTENER EL NOMBRE REAL DEL CLIENTE
      String clientName = await _getClientName(user);

      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }

      await _resolutionService.createResolutionCase(
        clientId: user.uid,
        clientName: clientName, // USAR EL NOMBRE REAL
        lawyerEmail: _selectedLawyer!.email,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caso de ${_selectedType == ResolutionType.mediation ? "mediación" : "arbitraje"} creado exitosamente'),
        ),
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear Nuevo Caso MARC',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            
            // Selector de tipo
            Text(
              'Tipo de Resolución',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    ResolutionType.mediation,
                    'Mediación',
                    'Proceso colaborativo',
                    Icons.handshake,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    ResolutionType.arbitration,
                    'Arbitraje',
                    'Decisión vinculante',
                    Icons.gavel,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del caso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción del conflicto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor describe el conflicto';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Monto (opcional)
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monto en disputa (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Ej: 5000.00',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 24),
            
            // Selector de abogado
            Text(
              'Seleccionar Abogado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            
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
            
            SizedBox(height: 32),
            
            // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createCase,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                        : Text('Crear Caso'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(ResolutionType type, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color.withOpacity(0.8) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
        TextFormField(
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
}