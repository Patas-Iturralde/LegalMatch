import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'live_chat_screen.dart';
import 'package:intl/intl.dart';

class AvailableChatsScreen extends StatefulWidget {
  @override
  _AvailableChatsScreenState createState() => _AvailableChatsScreenState();
}

class _AvailableChatsScreenState extends State<AvailableChatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'] ?? 'Abogado';
            _isLoading = false;
          });
        } else {
          setState(() {
            _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Abogado';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinChat(String chatId, String clientName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Verificar que el chat todavía esté disponible
      final chatDoc = await _firestore.collection('live_chats').doc(chatId).get();
      if (!chatDoc.exists || chatDoc.data()?['hasLawyer'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esta consulta ya no está disponible')),
        );
        return;
      }

      // Actualizar el chat con la información del abogado
      await _firestore.collection('live_chats').doc(chatId).update({
        'lawyerId': user.uid,
        'lawyerName': _userName,
        'hasLawyer': true,
      });

      // Añadir mensaje del sistema
      await _firestore
          .collection('live_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': '$_userName se ha unido al chat y te ayudará con tu consulta.',
        'senderId': 'system',
        'senderName': 'Sistema',
        'isLawyer': false,
        'timestamp': Timestamp.now(),
      });

      // Navegar a la pantalla de chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveChatScreen(
            userType: UserType.lawyer,
            chatId: chatId, // Asegúrate de que LiveChatScreen acepte este parámetro
          ),
        ),
      );
    } catch (e) {
      print('Error al unirse al chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al unirse al chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consultas Disponibles'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('live_chats')
                  .where('status', isEqualTo: 'active')
                  .where('hasLawyer', isEqualTo: false)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final availableChats = snapshot.data?.docs ?? [];

                if (availableChats.isEmpty) {
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
                          'No hay consultas disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Regresa más tarde cuando los clientes realicen consultas',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: availableChats.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final chatDoc = availableChats[index];
                    final chatData = chatDoc.data() as Map<String, dynamic>;
                    final clientName = chatData['userName'] ?? 'Cliente';
                    final createdAt = (chatData['createdAt'] as Timestamp).toDate();
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                    // Buscar el último mensaje del cliente para mostrar una vista previa
                    return FutureBuilder<QuerySnapshot>(
                      future: _firestore
                          .collection('live_chats')
                          .doc(chatDoc.id)
                          .collection('messages')
                          .where('isLawyer', isEqualTo: false)
                          .where('senderId', isNotEqualTo: 'system')
                          .orderBy('senderId') // Necesario para que funcione la condición anterior
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .get(),
                      builder: (context, messageSnapshot) {
                        String previewText = 'Cargando mensaje...';
                        
                        if (messageSnapshot.connectionState == ConnectionState.done) {
                          if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                            final messageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            previewText = messageData['text'] ?? 'Sin mensaje';
                            if (previewText.length > 100) {
                              previewText = previewText.substring(0, 100) + '...';
                            }
                          } else {
                            previewText = 'No hay mensajes disponibles';
                          }
                        }

                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _joinChat(chatDoc.id, clientName),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Icon(Icons.person),
                                        backgroundColor: Colors.blue.shade100,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              clientName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Creado: ${dateFormat.format(createdAt)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Vista previa:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    previewText,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () => _joinChat(chatDoc.id, clientName),
                                      child: Text('Unirse al chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}