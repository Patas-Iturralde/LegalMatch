import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gemini_service.dart';
import '../shared/ai_intro_card.dart';

class AIChatScreen extends StatefulWidget {
  final bool isLawyer;

  const AIChatScreen({Key? key, required this.isLawyer}) : super(key: key);

  @override
  AIChatScreenState createState() => AIChatScreenState();
}

class AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<AIMessage> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _loadOrCreateChat();
  }

  Future<void> _loadOrCreateChat() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Buscar chat activo del usuario
      final querySnapshot = await _firestore
          .collection('ai_chats')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _currentChatId = querySnapshot.docs.first.id;
        print('Chat existente encontrado: $_currentChatId');
        _loadMessages();
      } else {
        print('No hay chat existente, creando uno nuevo...');
        await _createNewChat();
      }
    } catch (e) {
      print('Error al cargar chat: $e');
      // Si hay error, intentar crear nuevo chat
      await _createNewChat();
    }
  }

  Future<void> _createNewChat() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final chatRef = await _firestore.collection('ai_chats').add({
        'userId': user.uid,
        'userEmail': user.email,
        'isLawyer': widget.isLawyer,
        'createdAt': Timestamp.now(),
        'lastActivity': Timestamp.now(),
        'isActive': true,
        'messageCount': 0,
      });

      _currentChatId = chatRef.id;

      // Mensaje de bienvenida
      await _addWelcomeMessage();
      
      // IMPORTANTE: Iniciar el stream de mensajes después de crear el chat
      _loadMessages();
    } catch (e) {
      print('Error al crear chat: $e');
    }
  }

  Future<void> _addWelcomeMessage() async {
    if (_currentChatId == null) {
      print('Error: _currentChatId es null en _addWelcomeMessage');
      return;
    }

    final welcomeText = widget.isLawyer
        ? '¡Hola! Soy tu asistente legal de IA. Puedo ayudarte a analizar consultas de clientes, clasificar casos y detectar urgencias. ¿En qué puedo ayudarte hoy?'
        : '¡Hola! Soy tu asistente legal de IA. Puedo ayudarte con orientación legal inicial, clasificar tu problema y preparar preguntas para abogados. ¿Cuál es tu consulta legal?';

    final aiMessage = AIMessage(
      id: '',
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
      specialty: null,
      isUrgent: false,
      confidence: null,
    );

    try {
      await _saveMessage(aiMessage);
      print('Mensaje de bienvenida guardado exitosamente');
    } catch (e) {
      print('Error al guardar mensaje de bienvenida: $e');
    }
  }

  void _loadMessages() {
    if (_currentChatId == null) {
      print('Error: _currentChatId es null en _loadMessages');
      return;
    }

    print('Cargando mensajes para chat: $_currentChatId');

    _firestore
        .collection('ai_chats')
        .doc(_currentChatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen(
          (snapshot) {
            print('Snapshot recibido: ${snapshot.docs.length} mensajes');
            setState(() {
              _messages = snapshot.docs
                  .map((doc) => AIMessage.fromMap(doc.data(), doc.id))
                  .toList();
            });
            _scrollToBottom();
          },
          onError: (error) {
            print('Error en stream de mensajes: $error');
          },
        );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _currentChatId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear mensaje del usuario
      final userMessage = AIMessage(
        id: '',
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
        specialty: null,
        isUrgent: false,
        confidence: null,
      );

      await _saveMessage(userMessage);

      // Obtener respuesta de IA
      if (widget.isLawyer) {
        await _processLawyerMessage(text);
      } else {
        await _processClientMessage(text);
      }

      _messageController.clear();
    } catch (e) {
      print('Error al enviar mensaje: $e');
      _showErrorMessage('Error al enviar mensaje. Intenta nuevamente.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processClientMessage(String text) async {
    try {
      // Análisis en paralelo
      final futures = await Future.wait([
        _geminiService.getLegalAdvice(text),
        _geminiService.classifyLegalSpecialty(text),
        _geminiService.isUrgentConsultation(text),
      ]);

      final advice = futures[0] as String;
      final specialty = futures[1] as String;
      final isUrgent = futures[2] as bool;

      // Crear mensaje de respuesta
      final aiMessage = AIMessage(
        id: '',
        text: advice,
        isUser: false,
        timestamp: DateTime.now(),
        specialty: specialty == 'Consulta No Válida' ? null : specialty,
        isUrgent: specialty == 'Consulta No Válida' ? false : isUrgent,
        confidence: specialty == 'Consulta No Válida' ? null : 0.85,
      );

      await _saveMessage(aiMessage);

      // Solo procesar como consulta legal válida si la especialidad no es "Consulta No Válida"
      if (specialty != 'Consulta No Válida') {
        // Si es urgente, agregar mensaje adicional
        if (isUrgent) {
          final urgentMessage = AIMessage(
            id: '',
            text: '⚠️ Tu consulta ha sido marcada como URGENTE. Te recomiendo buscar asesoría legal inmediata.',
            isUser: false,
            timestamp: DateTime.now(),
            specialty: null,
            isUrgent: true,
            confidence: null,
          );

          await _saveMessage(urgentMessage);
        }

        // Generar preguntas de seguimiento solo para consultas válidas
        final followUpQuestions = await _geminiService.generateFollowUpQuestions(text);
        if (followUpQuestions.isNotEmpty) {
          final questionsText = 'Para ayudarte mejor, ¿podrías responder algunas preguntas?\n\n' +
              followUpQuestions.asMap().entries
                  .map((entry) => '${entry.key + 1}. ${entry.value}')
                  .join('\n');

          final questionsMessage = AIMessage(
            id: '',
            text: questionsText,
            isUser: false,
            timestamp: DateTime.now(),
            specialty: null,
            isUrgent: false,
            confidence: null,
          );

          await _saveMessage(questionsMessage);
        }
      }
    } catch (e) {
      print('Error al procesar mensaje del cliente: $e');
      _showErrorMessage('Error al procesar tu consulta.');
    }
  }

  Future<void> _processLawyerMessage(String text) async {
    try {
      final advice = await _geminiService.getLegalAdvice(text);
      
      final aiMessage = AIMessage(
        id: '',
        text: advice,
        isUser: false,
        timestamp: DateTime.now(),
        specialty: null,
        isUrgent: false,
        confidence: 0.90,
      );

      await _saveMessage(aiMessage);
    } catch (e) {
      print('Error al procesar mensaje del abogado: $e');
      _showErrorMessage('Error al procesar tu consulta.');
    }
  }

  Future<void> _saveMessage(AIMessage message) async {
    if (_currentChatId == null) return;

    await _firestore
        .collection('ai_chats')
        .doc(_currentChatId)
        .collection('messages')
        .add(message.toMap());

    // Actualizar último actividad
    await _firestore.collection('ai_chats').doc(_currentChatId).update({
      'lastActivity': Timestamp.now(),
      'messageCount': FieldValue.increment(1),
    });
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Método público para nueva conversación (llamado desde AIAssistantScreen)
  void startNewChat() async {
    print('Iniciando nueva conversación...');
    
    // Marcar chat actual como inactivo
    if (_currentChatId != null) {
      await _firestore.collection('ai_chats').doc(_currentChatId).update({
        'isActive': false,
      });
    }

    // Limpiar estado actual
    setState(() {
      _messages.clear();
      _currentChatId = null;
    });

    // Crear nuevo chat (esto también iniciará el stream de mensajes)
    await _createNewChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Card de introducción (solo si no hay mensajes)
          if (_messages.isEmpty)
            AIIntroCard(isLawyer: widget.isLawyer),

          // Lista de mensajes
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Escribe tu primera consulta legal',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return AIMessageBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Indicador de carga
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'IA pensando...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Campo de entrada de mensajes
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: widget.isLawyer
                            ? 'Pregunta algo sobre análisis legal...'
                            : 'Describe tu problema legal...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : Colors.cyan,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Eliminar floatingActionButton para evitar superposiciones
    );
  }
}

// Modelo de mensaje de IA
class AIMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? specialty;
  final bool isUrgent;
  final double? confidence;

  AIMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.specialty,
    required this.isUrgent,
    this.confidence,
  });

  factory AIMessage.fromMap(Map<String, dynamic> data, String id) {
    return AIMessage(
      id: id,
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      specialty: data['specialty'],
      isUrgent: data['isUrgent'] ?? false,
      confidence: data['confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'specialty': specialty,
      'isUrgent': isUrgent,
      'confidence': confidence,
    };
  }
}

// Widget para mostrar mensajes de IA
class AIMessageBubble extends StatelessWidget {
  final AIMessage message;

  const AIMessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isUrgent ? Colors.red.shade100 : Colors.cyan.shade100,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: message.isUrgent ? Colors.red : Colors.cyan,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.cyan
                    : message.isUrgent
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                border: message.isUrgent
                    ? Border.all(color: Colors.red.shade200, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiquetas (especialidad, urgencia, confianza)
                  if (!message.isUser && (message.specialty != null || message.isUrgent))
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (message.specialty != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                message.specialty!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (message.isUrgent)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'URGENTE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (message.confidence != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${(message.confidence! * 100).toInt()}% confianza',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  // Texto del mensaje
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  
                  // Timestamp
                  SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}