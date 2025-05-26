import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/alternative_resolution.dart';
import '../../services/alternative_resolution_service.dart';

class ResolutionCaseDetailScreen extends StatefulWidget {
  final AlternativeResolutionCase
      resolutionCase; // Cambiado de 'case' a 'resolutionCase'
  final bool isLawyer;

  ResolutionCaseDetailScreen({
    required this.resolutionCase, // Cambiado de 'case' a 'resolutionCase'
    required this.isLawyer,
  });

  @override
  _ResolutionCaseDetailScreenState createState() =>
      _ResolutionCaseDetailScreenState();
}

class _ResolutionCaseDetailScreenState extends State<ResolutionCaseDetailScreen>
    with SingleTickerProviderStateMixin {
  final AlternativeResolutionService _resolutionService =
      AlternativeResolutionService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  bool _showProposalForm = false;
  bool _showDecisionForm = false;
  final _proposalController = TextEditingController();
  final _proposalAmountController = TextEditingController();
  final _decisionController = TextEditingController();
  final _decisionAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _proposalController.dispose();
    _proposalAmountController.dispose();
    _decisionController.dispose();
    _decisionAmountController.dispose();
    super.dispose();
  }

 // Añadir este método auxiliar al inicio de la clase _ResolutionCaseDetailScreenState

// MÉTODO AUXILIAR PARA OBTENER NOMBRES REALES DE USUARIOS
Future<String> _getUserRealName(String userId) async {
  try {
    // Primero verificar si es uno de los participantes conocidos del caso
    if (userId == widget.resolutionCase.clientId) {
      return widget.resolutionCase.clientName;
    } else if (userId == widget.resolutionCase.lawyerId) {
      return widget.resolutionCase.lawyerName;
    }
    
    // Si no, buscar en la base de datos de usuarios
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['name'] ?? '';
      if (userName.isNotEmpty) {
        return userName;
      }
    }
    
    // Buscar en la colección de abogados como fallback
    final lawyerDoc = await FirebaseFirestore.instance
        .collection('lawyers')
        .doc(userId)
        .get();
    
    if (lawyerDoc.exists) {
      final lawyerData = lawyerDoc.data() as Map<String, dynamic>;
      return lawyerData['name'] ?? 'Usuario';
    }
    
    return 'Usuario';
  } catch (e) {
    print('Error al obtener nombre real del usuario: $e');
    return 'Usuario';
  }
}

// REEMPLAZAR el método _sendMessage existente con este:
Future<void> _sendMessage() async {
  final message = _messageController.text.trim();
  if (message.isEmpty) return;

  try {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // Obtener el nombre real del usuario actual
    String senderName = await _getUserRealName(user.uid);

    await _resolutionService.sendMessage(
      caseId: widget.resolutionCase.id,
      senderId: user.uid,
      senderName: senderName, // Usar el nombre real obtenido
      senderType: widget.isLawyer ? 'lawyer' : 'client',
      message: message,
    );

    _messageController.clear();
    _scrollToBottom();

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar mensaje: $e')),
    );
  }
}

// REEMPLAZAR el método _makeProposal existente con este:
Future<void> _makeProposal() async {
  if (_proposalController.text.trim().isEmpty) return;

  try {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // Obtener el nombre real del usuario
    String senderName = await _getUserRealName(user.uid);

    double? amount;
    if (_proposalAmountController.text.isNotEmpty) {
      amount = double.tryParse(_proposalAmountController.text);
    }

    await _resolutionService.makeProposal(
      caseId: widget.resolutionCase.id,
      senderId: user.uid,
      senderName: senderName, // Usar el nombre real
      senderType: widget.isLawyer ? 'lawyer' : 'client',
      proposal: _proposalController.text.trim(),
      amount: amount,
    );

    _proposalController.clear();
    _proposalAmountController.clear();
    setState(() {
      _showProposalForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Propuesta enviada exitosamente')),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar propuesta: $e')),
    );
  }
}

// REEMPLAZAR el método _makeDecision existente con este:
Future<void> _makeDecision() async {
  if (_decisionController.text.trim().isEmpty) return;

  try {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // Obtener el nombre real del árbitro
    String arbitratorName = await _getUserRealName(user.uid);

    double? amount;
    if (_decisionAmountController.text.isNotEmpty) {
      amount = double.tryParse(_decisionAmountController.text);
    }

    await _resolutionService.makeArbitrationDecision(
      caseId: widget.resolutionCase.id,
      arbitratorId: user.uid,
      arbitratorName: arbitratorName, // Usar el nombre real
      decision: _decisionController.text.trim(),
      awardAmount: amount,
    );

    _decisionController.clear();
    _decisionAmountController.clear();
    setState(() {
      _showDecisionForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Decisión de arbitraje enviada')),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar decisión: $e')),
    );
  }
}


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        DateTime selectedDate = DateTime.now().add(Duration(days: 1));
        TimeOfDay selectedTime = TimeOfDay(hour: 10, minute: 0);
        final notesController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Programar Sesión'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text('Fecha'),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text('Hora'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() {
                            selectedTime = time;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    try {
                      await _resolutionService.scheduleSession(
                        caseId: widget.resolutionCase.id, // Cambiado
                        scheduledDate: scheduledDateTime,
                        scheduledBy: widget.isLawyer ? 'lawyer' : 'client',
                        notes: notesController.text.trim(),
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Sesión programada exitosamente')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error al programar sesión: $e')),
                      );
                    }
                  },
                  child: Text('Programar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resolutionCase.title), // Cambiado
        actions: [
          if (widget.resolutionCase.status == 'active') // Cambiado
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'schedule',
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 8),
                      Text('Programar Sesión'),
                    ],
                  ),
                ),
                if (widget.resolutionCase.type ==
                    ResolutionType.mediation) // Cambiado
                  PopupMenuItem(
                    value: 'proposal',
                    child: Row(
                      children: [
                        Icon(Icons.handshake),
                        SizedBox(width: 8),
                        Text('Hacer Propuesta'),
                      ],
                    ),
                  ),
                if (widget.resolutionCase.type == ResolutionType.arbitration &&
                    widget.isLawyer) // Cambiado
                  PopupMenuItem(
                    value: 'decision',
                    child: Row(
                      children: [
                        Icon(Icons.gavel),
                        SizedBox(width: 8),
                        Text('Emitir Decisión'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar Caso', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'schedule':
                    _showScheduleDialog();
                    break;
                  case 'proposal':
                    setState(() {
                      _showProposalForm = true;
                      _showDecisionForm = false;
                    });
                    break;
                  case 'decision':
                    setState(() {
                      _showDecisionForm = true;
                      _showProposalForm = false;
                    });
                    break;
                  case 'close':
                    _showCloseDialog();
                    break;
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Chat'),
            Tab(text: 'Información'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildInfoTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Formularios especiales
        if (_showProposalForm) _buildProposalForm(),
        if (_showDecisionForm) _buildDecisionForm(),

        // Chat
        Expanded(
          child: StreamBuilder<List<ResolutionMessage>>(
            stream: _resolutionService
                .getCaseMessages(widget.resolutionCase.id), // Cambiado
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              // Reemplaza la sección del estado vacío en _buildChatTab()
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.resolutionCase.type ==
                                  ResolutionType.mediation
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.resolutionCase.type == ResolutionType.mediation
                              ? Icons.handshake
                              : Icons.gavel,
                          size: 48,
                          color: widget.resolutionCase.type ==
                                  ResolutionType.mediation
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        widget.resolutionCase.type == ResolutionType.mediation
                            ? 'Mediación Iniciada'
                            : 'Arbitraje Iniciado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.resolutionCase.type ==
                                  ResolutionType.mediation
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        margin: EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Participantes:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.person,
                                            size: 16, color: Colors.blue),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.resolutionCase.clientName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Cliente',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.grey[400]),
                                Expanded(
                                  child: Row(
                                    children: [
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.verified,
                                            size: 16, color: Colors.teal),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.resolutionCase.lawyerName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              widget.resolutionCase.type ==
                                                      ResolutionType.mediation
                                                  ? 'Mediador'
                                                  : 'Árbitro',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: widget.resolutionCase.type ==
                                  ResolutionType.mediation
                              ? Colors.green.withOpacity(0.05)
                              : Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.resolutionCase.type ==
                                    ResolutionType.mediation
                                ? Colors.green.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.resolutionCase.type ==
                                      ResolutionType.mediation
                                  ? '🤝 Proceso de Mediación'
                                  : '⚖️ Proceso de Arbitraje',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: widget.resolutionCase.type ==
                                        ResolutionType.mediation
                                    ? Colors.green[700]
                                    : Colors.blue[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.resolutionCase.type ==
                                      ResolutionType.mediation
                                  ? 'Trabajan juntos para encontrar una solución colaborativa. El diálogo abierto y la comprensión mutua son clave.'
                                  : 'Cada parte presenta sus argumentos y evidencias. El árbitro tomará una decisión imparcial y vinculante.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Escribe el primer mensaje para comenzar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }

              _scrollToBottom();

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

        // Input de mensaje
        if (widget.resolutionCase.status == 'active') // Cambiado
          _buildMessageInput(),
      ],
    );
  }

  Widget _buildProposalForm() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.green.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: Colors.green[700]),
              SizedBox(width: 8),
              Text(
                'Hacer Propuesta de Acuerdo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showProposalForm = false;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _proposalController,
            decoration: InputDecoration(
              labelText: 'Propuesta de acuerdo',
              border: OutlineInputBorder(),
              hintText: 'Describe tu propuesta de resolución...',
            ),
            maxLines: 3,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _proposalAmountController,
                  decoration: InputDecoration(
                    labelText: 'Monto (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _makeProposal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text('Enviar Propuesta'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionForm() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'Emitir Decisión de Arbitraje',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showDecisionForm = false;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta decisión será vinculante para ambas partes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _decisionController,
            decoration: InputDecoration(
              labelText: 'Decisión del árbitro',
              border: OutlineInputBorder(),
              hintText:
                  'Describe tu decisión basada en los argumentos presentados...',
            ),
            maxLines: 4,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _decisionAmountController,
                  decoration: InputDecoration(
                    labelText: 'Monto del laudo (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _makeDecision,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text('Emitir Decisión'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ResolutionMessage message) {
  final user = Provider.of<User?>(context);
  final isCurrentUser = message.senderId == user?.uid;
  final isSystemMessage = message.isSystemMessage;
  final isLawyer = message.senderType == 'lawyer';

  // VERIFICAR SI LA PROPUESTA YA FUE RESPONDIDA
  final bool isProposalResponded = message.messageType == MessageType.proposal && 
                                   message.proposalStatus != null && 
                                   message.proposalStatus != 'pending';

  if (isSystemMessage) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Sistema MARC',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.0),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Definir colores y alineación basados en el remitente
  Color bubbleColor;
  Color textColor;
  Color nameColor;
  Alignment alignment;
  CrossAxisAlignment crossAlignment;

  if (message.messageType == MessageType.proposal) {
    bubbleColor = Colors.green.withOpacity(0.15);
    textColor = Colors.green[900]!;
    nameColor = Colors.green[700]!;
    alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    crossAlignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  } else if (message.messageType == MessageType.decision) {
    bubbleColor = Colors.blue.withOpacity(0.15);
    textColor = Colors.blue[900]!;
    nameColor = Colors.blue[700]!;
    alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    crossAlignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  } else if (isCurrentUser) {
    // Mensajes del usuario actual (siempre a la derecha)
    bubbleColor = Theme.of(context).primaryColor;
    textColor = Colors.white;
    nameColor = Colors.white70;
    alignment = Alignment.centerRight;
    crossAlignment = CrossAxisAlignment.end;
  } else {
    // Mensajes de otros usuarios (siempre a la izquierda)
    if (isLawyer) {
      bubbleColor = Colors.teal.shade50;
      textColor = Colors.teal.shade900;
      nameColor = Colors.teal.shade700;
    } else {
      bubbleColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
      nameColor = Colors.blue.shade700;
    }
    alignment = Alignment.centerLeft;
    crossAlignment = CrossAxisAlignment.start;
  }

  return Padding(
    padding: EdgeInsets.only(bottom: 12.0),
    child: Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: crossAlignment,
        children: [
          // Mostrar nombre del remitente si no es el usuario actual
          if (!isCurrentUser)
            Padding(
              padding: EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                bottom: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLawyer)
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified,
                        size: 12.0,
                        color: Colors.white,
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 12.0,
                        color: Colors.white,
                      ),
                    ),
                  SizedBox(width: 6.0),
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: nameColor,
                    ),
                  ),
                  if (isLawyer)
                    Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        '(${widget.resolutionCase.type == ResolutionType.mediation ? "Mediador" : "Árbitro"})',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Burbuja del mensaje
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isCurrentUser ? 18.0 : 6.0),
                topRight: Radius.circular(isCurrentUser ? 6.0 : 18.0),
                bottomLeft: Radius.circular(18.0),
                bottomRight: Radius.circular(18.0),
              ),
              border: message.messageType != MessageType.text
                  ? Border.all(
                      color: message.messageType == MessageType.proposal
                          ? Colors.green
                          : Colors.blue,
                      width: 2.0,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta especial para propuestas y decisiones
                if (message.messageType != MessageType.text)
                  Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: message.messageType == MessageType.proposal
                          ? Colors.green
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.messageType == MessageType.proposal
                              ? Icons.handshake
                              : Icons.gavel,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          message.messageType == MessageType.proposal
                              ? 'PROPUESTA DE ACUERDO'
                              : 'DECISIÓN DE ARBITRAJE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Contenido del mensaje
                Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 15.0,
                    color: textColor,
                    height: 1.4,
                  ),
                ),

                // MOSTRAR ESTADO DE LA PROPUESTA SI YA FUE RESPONDIDA
                if (message.messageType == MessageType.proposal && isProposalResponded)
                  Container(
                    margin: EdgeInsets.only(top: 8.0),
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: message.proposalStatus == 'accepted' 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: message.proposalStatus == 'accepted' 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.proposalStatus == 'accepted' 
                              ? Icons.check_circle 
                              : Icons.cancel,
                          size: 14,
                          color: message.proposalStatus == 'accepted' 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          message.proposalStatus == 'accepted' 
                              ? 'PROPUESTA ACEPTADA' 
                              : 'PROPUESTA RECHAZADA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: message.proposalStatus == 'accepted' 
                                ? Colors.green[700] 
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Timestamp
                Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isCurrentUser ? Colors.white60 : Colors.grey[500],
                    ),
                  ),
                ),

                // Botones de acción para propuestas - SOLO SI NO HA SIDO RESPONDIDA
                if (message.messageType == MessageType.proposal &&
                    !isCurrentUser &&
                    widget.resolutionCase.type == ResolutionType.mediation &&
                    widget.resolutionCase.status == 'active' &&
                    !isProposalResponded) // NUEVA CONDICIÓN
                  Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.check, size: 16),
                            label: Text('Aceptar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showAcceptDialog(message.message, message.id),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.close, size: 16),
                            label: Text('Rechazar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showRejectDialog(message.message, message.id),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // Input de mensajes corregido con nombres reales
Widget _buildMessageInput() {
  final user = Provider.of<User?>(context);
  
  // Obtener el nombre real del usuario actual
  String userName;
  String userRole;
  
  if (user?.uid == widget.resolutionCase.clientId) {
    userName = widget.resolutionCase.clientName;
    userRole = 'Cliente';
  } else if (user?.uid == widget.resolutionCase.lawyerId) {
    userName = widget.resolutionCase.lawyerName;
    userRole = widget.resolutionCase.type == ResolutionType.mediation ? 'Mediador' : 'Árbitro';
  } else {
    userName = user?.displayName ?? 'Usuario';
    userRole = widget.isLawyer 
        ? (widget.resolutionCase.type == ResolutionType.mediation ? 'Mediador' : 'Árbitro')
        : 'Cliente';
  }

  return Container(
    padding: EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador de quién está escribiendo con nombre real
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: widget.isLawyer ? Colors.teal.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isLawyer ? Icons.verified : Icons.person,
                size: 14,
                color: widget.isLawyer ? Colors.teal : Colors.blue,
              ),
              SizedBox(width: 6),
              Text(
                'Escribiendo como: $userName ($userRole)', // Nombre real
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isLawyer ? Colors.teal[700] : Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.0),
        
        // Campo de texto y botón de envío
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: widget.resolutionCase.type == ResolutionType.mediation
                        ? 'Escribe tu mensaje para la mediación...'
                        : 'Presenta tu argumento...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ),
            SizedBox(width: 8.0),
            
            // Botón de envío mejorado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24.0),
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Información contextual según el tipo de proceso
        if (widget.resolutionCase.type == ResolutionType.mediation)
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber[700]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Recuerda: En mediación busca soluciones colaborativas',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.balance, size: 14, color: Colors.blue[700]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.isLawyer 
                        ? 'Como árbitro: Analiza objetivamente los argumentos'
                        : 'Presenta evidencias claras y argumentos sólidos',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}


  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          SizedBox(height: 16),
          _buildParticipantsCard(),
          SizedBox(height: 16),
          _buildProcessInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.resolutionCase.type ==
                          ResolutionType.mediation // Cambiado
                      ? Icons.handshake
                      : Icons.gavel,
                  color: widget.resolutionCase.type ==
                          ResolutionType.mediation // Cambiado
                      ? Colors.green
                      : Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Información del Caso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildInfoRow(
                'Tipo:', widget.resolutionCase.typeDisplayName), // Cambiado
            _buildInfoRow('Estado:',
                _getStatusText(widget.resolutionCase.status)), // Cambiado
            _buildInfoRow(
                'Creado:',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(widget.resolutionCase.createdAt)), // Cambiado

            if (widget.resolutionCase.scheduledAt != null) // Cambiado
              _buildInfoRow(
                  'Sesión programada:',
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(widget.resolutionCase.scheduledAt!)), // Cambiado

            if (widget.resolutionCase.amount != null) // Cambiado
              _buildInfoRow('Monto en disputa:',
                  '\${widget.resolutionCase.amount!.toStringAsFixed(2)}'), // Cambiado

            if (widget.resolutionCase.resolvedAt != null) // Cambiado
              _buildInfoRow(
                  'Resuelto:',
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(widget.resolutionCase.resolvedAt!)), // Cambiado

            SizedBox(height: 12),
            Text(
              'Descripción:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(widget.resolutionCase.description), // Cambiado

            if (widget.resolutionCase.resolution != null) ...[
              // Cambiado
              SizedBox(height: 12),
              Text(
                'Resolución:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(widget.resolutionCase.resolution!), // Cambiado
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participantes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(widget.resolutionCase.clientName), // Cambiado
              subtitle: Text('Cliente'),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.2),
                child: Icon(Icons.business, color: Colors.green),
              ),
              title: Text(widget.resolutionCase.lawyerName), // Cambiado
              subtitle: Text(
                  widget.resolutionCase.type == ResolutionType.mediation
                      ? 'Mediador'
                      : 'Árbitro'), // Cambiado
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Proceso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              widget.resolutionCase.typeDisplayName, // Cambiado
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              widget.resolutionCase.typeDescription, // Cambiado
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
            SizedBox(height: 16),
            if (widget.resolutionCase.type == ResolutionType.mediation) ...[
              // Cambiado
              _buildProcessStep(
                '1. Diálogo',
                'Las partes expresan sus puntos de vista',
                Icons.forum,
                Colors.blue,
              ),
              _buildProcessStep(
                '2. Negociación',
                'Se buscan soluciones mutuamente beneficiosas',
                Icons.handshake,
                Colors.orange,
              ),
              _buildProcessStep(
                '3. Acuerdo',
                'Se alcanza un acuerdo voluntario',
                Icons.check_circle,
                Colors.green,
              ),
            ] else ...[
              _buildProcessStep(
                '1. Presentación',
                'Cada parte presenta sus argumentos',
                Icons.present_to_all,
                Colors.blue,
              ),
              _buildProcessStep(
                '2. Análisis',
                'El árbitro evalúa las evidencias',
                Icons.analytics,
                Colors.orange,
              ),
              _buildProcessStep(
                '3. Decisión',
                'Se emite una decisión vinculante',
                Icons.gavel,
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método corregido para aceptar propuestas
// MÉTODO _showAcceptDialog COMPLETO CON LOS CAMBIOS
void _showAcceptDialog(String proposal, String messageId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Aceptar Propuesta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres aceptar esta propuesta?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                proposal,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Al aceptar, se creará un acuerdo que ambas partes deberán cumplir.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
                final user = Provider.of<User?>(context, listen: false);
                if (user != null) {
                  // Obtener el nombre real del usuario que acepta
                  String acceptorName = await _getUserRealName(user.uid);

                  await _resolutionService.acceptProposal(
                    caseId: widget.resolutionCase.id,
                    acceptorId: user.uid,
                    acceptorName: acceptorName,
                    proposalContent: proposal,
                    originalMessageId: messageId, // PASAR EL MESSAGE ID
                  );
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Propuesta aceptada exitosamente')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

// Método corregido para rechazar propuestas
void _showRejectDialog(String proposal, String messageId) {
  final reasonController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Rechazar Propuesta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Por qué rechazas esta propuesta?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                proposal,
                style: TextStyle(fontStyle: FontStyle.italic),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Razón del rechazo',
                border: OutlineInputBorder(),
                hintText: 'Explica por qué no aceptas esta propuesta...',
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor proporciona una razón')),
                );
                return;
              }
              
              try {
                final user = Provider.of<User?>(context, listen: false);
                if (user != null) {
                  // Obtener el nombre real del usuario que rechaza
                  String rejectorName = await _getUserRealName(user.uid);

                  await _resolutionService.rejectProposal(
                    caseId: widget.resolutionCase.id,
                    rejectorId: user.uid,
                    rejectorName: rejectorName,
                    reason: reasonController.text.trim(),
                    originalMessageId: messageId, // PASAR EL MESSAGE ID
                  );
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Propuesta rechazada')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Rechazar'),
          ),
        ],
      );
    },
  );
}

  void _showCloseDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cerrar Caso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Estás seguro de que quieres cerrar este caso?'),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Razón del cierre',
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
                  await _resolutionService.closeCase(
                    caseId: widget.resolutionCase.id, // Cambiado
                    reason: reasonController.text.trim().isEmpty
                        ? 'Caso cerrado por solicitud del usuario'
                        : reasonController.text.trim(),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Caso cerrado exitosamente')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Cerrar Caso'),
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
}
