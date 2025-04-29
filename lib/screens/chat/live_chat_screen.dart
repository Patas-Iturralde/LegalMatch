import 'dart:convert';

import 'package:abogados/models/lawyer.dart';
import 'package:abogados/screens/home/lawyer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class LiveChatScreen extends StatefulWidget {
  final UserType userType;
  final String? chatId;

  LiveChatScreen({
    required this.userType,
    this.chatId,
  });

  @override
  _LiveChatScreenState createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedSpecialty;
  List<String> _specialties = [];
  bool _isRecommending = false;
  bool _isJoiningChat = true;
  String? _activeChatId;
  String? _userName;
  bool _noChatsAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    _getUserInfo();

    // Pequeño retraso para asegurar que la información de usuario esté cargada
    Future.delayed(Duration(milliseconds: 500), () {
      _loadOrCreateChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Cargar las especialidades disponibles
  Future<void> _loadSpecialties() async {
    try {
      final snapshot = await _firestore.collection('specialties').get();
      setState(() {
        _specialties =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error al cargar especialidades: $e');
    }
  }

  // Obtener información del usuario actual
  Future<void> _getUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'] ?? 'Usuario';
          });
        } else {
          setState(() {
            _userName =
                user.displayName ?? user.email?.split('@')[0] ?? 'Usuario';
          });
        }
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
    }
  }

  // Cargar o crear una sala de chat
  Future<void> _loadOrCreateChat() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print(
          'Cargando/creando chat como ${widget.userType == UserType.lawyer ? "abogado" : "cliente"} para usuario: ${user.uid}');

      if (widget.chatId != null) {
        print('Usando chatId proporcionado: ${widget.chatId}');
        final chatDoc =
            await _firestore.collection('live_chats').doc(widget.chatId).get();

        if (chatDoc.exists) {
          setState(() {
            _activeChatId = widget.chatId;
            _isJoiningChat = false;
          });
          return;
        }
      }

      // Si es abogado, primero verificar si ya tiene un chat asignado
      if (widget.userType == UserType.lawyer) {
        print('Verificando si el abogado ya tiene un chat asignado...');

        final lawyerChatsQuery = await _firestore
            .collection('live_chats')
            .where('lawyerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .get();

        if (lawyerChatsQuery.docs.isNotEmpty) {
          final chatDoc = lawyerChatsQuery.docs.first;
          print('Abogado ya tiene un chat asignado con ID: ${chatDoc.id}');

          setState(() {
            _activeChatId = chatDoc.id;
            _isJoiningChat = false;
          });
          return;
        }

        print(
            'Abogado no tiene chats asignados, buscando chats disponibles...');

        // Buscar chats sin abogado asignado
        final availableChatsQuery = await _firestore
            .collection('live_chats')
            .where('status', isEqualTo: 'active')
            .where('hasLawyer', isEqualTo: false)
            .get();

        print(
            'Chats disponibles encontrados: ${availableChatsQuery.docs.length}');

        if (availableChatsQuery.docs.isNotEmpty) {
          // Tomar el primer chat disponible
          final chatDoc = availableChatsQuery.docs.first;
          print('Uniendo al abogado al chat con ID: ${chatDoc.id}');

          // Actualizar el chat con la información del abogado
          await _firestore.collection('live_chats').doc(chatDoc.id).update({
            'lawyerId': user.uid,
            'lawyerName': _userName ?? 'Abogado',
            'hasLawyer': true,
          });

          // Añadir mensaje del sistema
          await _firestore
              .collection('live_chats')
              .doc(chatDoc.id)
              .collection('messages')
              .add({
            'text':
                '$_userName se ha unido al chat y te ayudará con tu consulta.',
            'senderId': 'system',
            'senderName': 'Sistema',
            'isLawyer': false,
            'timestamp': Timestamp.now(),
          });

          setState(() {
            _activeChatId = chatDoc.id;
            _isJoiningChat = false;
          });
        } else {
          // No hay chats disponibles
          print('No hay chats disponibles para el abogado');
          setState(() {
            _isJoiningChat = false;
            _noChatsAvailable = true;
          });
        }
      } else {
        // Es cliente, verificar si ya tiene un chat activo
        final clientChatsQuery = await _firestore
            .collection('live_chats')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .get();

        if (clientChatsQuery.docs.isNotEmpty) {
          final chatDoc = clientChatsQuery.docs.first;
          print('Cliente ya tiene un chat activo con ID: ${chatDoc.id}');

          setState(() {
            _activeChatId = chatDoc.id;
            _isJoiningChat = false;
          });
          return;
        }

        print('Cliente no tiene chats activos, creando uno nuevo...');

        // Crear un nuevo chat para el cliente
        final newChatRef = await _firestore.collection('live_chats').add({
          'userId': user.uid,
          'userName': _userName ?? 'Cliente',
          'createdAt': Timestamp.now(),
          'status': 'active',
          'hasLawyer': false,
          'lawyerId': null,
          'lawyerName': null,
          'recommendedSpecialty': null,
        });

        print('Nuevo chat creado para cliente con ID: ${newChatRef.id}');

        // Añadir mensaje de bienvenida
        await _firestore
            .collection('live_chats')
            .doc(newChatRef.id)
            .collection('messages')
            .add({
          'text':
              'Bienvenido al chat en vivo. Describe tu problema legal y un abogado te ayudará pronto.',
          'senderId': 'system',
          'senderName': 'Sistema',
          'isLawyer': false,
          'timestamp': Timestamp.now(),
        });

        setState(() {
          _activeChatId = newChatRef.id;
          _isJoiningChat = false;
        });
      }
    } catch (e) {
      print('Error en _loadOrCreateChat: $e');
      setState(() {
        _isJoiningChat = false;
      });
    }
  }

  // Enviar un mensaje
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _activeChatId == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('live_chats')
          .doc(_activeChatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': user.uid,
        'senderName': _userName ?? 'Usuario',
        'isLawyer': widget.userType == UserType.lawyer,
        'timestamp': Timestamp.now(),
      });

      _messageController.clear();

      // Scroll al final de la lista
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
      print('Error al enviar mensaje: $e');
    }
  }

  // Recomendar una especialidad
  Future<void> _recommendSpecialty() async {
    if (_selectedSpecialty == null || _activeChatId == null) return;

    setState(() {
      _isRecommending = true;
    });

    try {
      // Actualizar el chat con la especialidad recomendada
      await _firestore.collection('live_chats').doc(_activeChatId).update({
        'recommendedSpecialty': _selectedSpecialty,
      });

      // Enviar mensaje de recomendación
      await _firestore
          .collection('live_chats')
          .doc(_activeChatId)
          .collection('messages')
          .add({
        'text':
            'Basado en tu consulta, te recomiendo buscar un abogado especializado en $_selectedSpecialty',
        'senderId': _auth.currentUser!.uid,
        'senderName': _userName ?? 'Abogado',
        'isLawyer': true,
        'isRecommendation': true,
        'specialty': _selectedSpecialty,
        'timestamp': Timestamp.now(),
      });

      setState(() {
        _isRecommending = false;
        _selectedSpecialty = null;
      });
    } catch (e) {
      print('Error al recomendar especialidad: $e');
      setState(() {
        _isRecommending = false;
      });
    }
  }

  // Finalizar chat
  Future<void> _endChat() async {
    if (_activeChatId == null) return;

    try {
      await _firestore.collection('live_chats').doc(_activeChatId).update({
        'status': 'closed',
        'closedAt': Timestamp.now(),
      });

      // Agregar mensaje de cierre
      await _firestore
          .collection('live_chats')
          .doc(_activeChatId)
          .collection('messages')
          .add({
        'text':
            'Chat finalizado por ${widget.userType == UserType.lawyer ? 'el abogado' : 'el cliente'}',
        'senderId': 'system',
        'senderName': 'Sistema',
        'isLawyer': false,
        'timestamp': Timestamp.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error al finalizar chat: $e');
    }
  }

  // Buscar nuevamente chats disponibles (útil para abogados)
  Future<void> _refreshAvailableChats() async {
    setState(() {
      _isJoiningChat = true;
      _noChatsAvailable = false;
    });

    await _loadOrCreateChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat en Vivo'),
        centerTitle: true,
        actions: [
          if (_activeChatId != null)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _endChat,
              tooltip: 'Finalizar chat',
            ),
        ],
      ),
      body: _isJoiningChat
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(widget.userType == UserType.lawyer
                      ? 'Buscando consultas de clientes...'
                      : 'Iniciando chat, espera un momento...'),
                ],
              ),
            )
          : _noChatsAvailable
              ? _buildNoChatsAvailable()
              : _activeChatId == null
                  ? Center(
                      child: Text(widget.userType == UserType.lawyer
                          ? 'No hay consultas disponibles en este momento'
                          : 'Error al iniciar el chat. Intenta nuevamente.'),
                    )
                  : _buildChatInterface(),
    );
  }

  Widget _buildNoChatsAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay consultas disponibles en este momento',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los clientes aún no han iniciado consultas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshAvailableChats,
            icon: Icon(Icons.refresh),
            label: Text('Buscar nuevamente'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Panel de recomendación para abogados
        if (widget.userType == UserType.lawyer)
          Container(
            padding: EdgeInsets.all(12.0),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Recomendar especialidad',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    value: _selectedSpecialty,
                    items: _specialties.map((specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecialty = value;
                      });
                    },
                    hint: Text('Seleccionar especialidad'),
                  ),
                ),
                SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: _selectedSpecialty == null || _isRecommending
                      ? null
                      : _recommendSpecialty,
                  child: _isRecommending
                      ? SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Recomendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),

        // Mensajes
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('live_chats')
                .doc(_activeChatId)
                .collection('messages')
                .orderBy('timestamp')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error al cargar mensajes: ${snapshot.error}'));
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Text(widget.userType == UserType.lawyer
                      ? 'Esperando la consulta del cliente...'
                      : 'Describe tu problema legal y un abogado te ayudará pronto...'),
                );
              }

              // Lista de mensajes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController
                      .jumpTo(_scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemBuilder: (context, index) {
                  final messageData =
                      messages[index].data() as Map<String, dynamic>;
                  final isCurrentUser =
                      messageData['senderId'] == _auth.currentUser?.uid;
                  final isSystemMessage = messageData['senderId'] == 'system';
                  final isLawyer = messageData['isLawyer'] ?? false;
                  final isRecommendation =
                      messageData['isRecommendation'] ?? false;
                  final timestamp = messageData['timestamp'] as Timestamp;
                  final dateTime = timestamp.toDate();
                  final timeFormat = DateFormat.Hm();

                  if (isSystemMessage) {
                    return _buildSystemMessage(
                        messageData['text'], dateTime, timeFormat);
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isRecommendation
                              ? Colors.green.shade100
                              : isLawyer
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  messageData['senderName'] ?? 'Usuario',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: isLawyer
                                        ? Colors.blue.shade800
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(width: 4.0),
                                if (isLawyer)
                                  Icon(
                                    Icons.verified,
                                    size: 12.0,
                                    color: Colors.blue.shade800,
                                  ),
                                Spacer(),
                                Text(
                                  timeFormat.format(dateTime),
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              messageData['text'] ?? '',
                              style: TextStyle(fontSize: 15.0),
                            ),
                            if (isRecommendation &&
                                widget.userType == UserType.client)
                              Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: _buildLawyersBySpecialtyDropdown(
                                    messageData['specialty']),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Área de entrada de texto
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
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
    );
  }

  Widget _buildLawyersBySpecialtyDropdown(String specialty) {
    return FutureBuilder<List<Lawyer>>(
      future: _getLawyersBySpecialty(specialty),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Cargando abogados disponibles...')
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Text('Error al cargar abogados: ${snapshot.error}',
              style: TextStyle(color: Colors.red));
        }

        final lawyers = snapshot.data ?? [];

        if (lawyers.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No hay abogados disponibles con esta especialidad',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abogados disponibles:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
            SizedBox(height: 6.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Selecciona un abogado'),
                  ),
                  value: null,
                  items: lawyers.map((lawyer) {
                    return DropdownMenuItem<String>(
                      value: lawyer.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            if (lawyer.photoBase64.isNotEmpty)
                              Container(
                                width: 24,
                                height: 24,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: MemoryImage(
                                        base64Decode(lawyer.photoBase64)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: Icon(Icons.person,
                                    size: 14, color: Colors.grey[600]),
                              ),
                            Expanded(
                              child: Text(
                                '${lawyer.name} - \$${lawyer.consultationPrice}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                SizedBox(width: 2),
                                Text(
                                  lawyer.rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (lawyerId) {
                    if (lawyerId != null) {
                      _navigateToLawyerDetail(lawyerId);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 8.0),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, specialty);
              },
              icon: Icon(Icons.search, size: 16.0),
              label: Text('Ver todos los abogados de esta especialidad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                textStyle: TextStyle(fontSize: 12.0),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Lawyer>> _getLawyersBySpecialty(String specialty) async {
    try {
      final querySnapshot = await _firestore
          .collection('lawyers')
          .where('specialty', isEqualTo: specialty)
          .get();

      return querySnapshot.docs
          .map((doc) => Lawyer.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) =>
            b.rating.compareTo(a.rating)); // Ordenar por rating descendente
    } catch (e) {
      print('Error al obtener abogados por especialidad: $e');
      return [];
    }
  }

// Añade este método para navegar al detalle del abogado

  void _navigateToLawyerDetail(String lawyerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawyerDetailScreen(lawyerId: lawyerId),
      ),
    );
  }

  Widget _buildSystemMessage(
      String text, DateTime dateTime, DateFormat timeFormat) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.0),
              Text(
                timeFormat.format(dateTime),
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
