import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/forum.dart';
import '../../services/forum_service.dart';
import '../../services/auth_service.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final ForumTopic topic;

  ForumTopicDetailScreen({required this.topic});

  @override
  _ForumTopicDetailScreenState createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  final ForumService _forumService = ForumService();
  final AuthService _authService = AuthService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  String? _replyingToId;
  String? _replyingToAuthor;

  @override
  void initState() {
    super.initState();
    // Incrementar vistas del tema
    _forumService.incrementTopicViews(widget.topic.id);
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) throw Exception('Usuario no autenticado');

      final userType = await _authService.getUserType(user.uid);

      await _forumService.addReply(
        topicId: widget.topic.id,
        content: replyText,
        authorId: user.uid,
        authorName: user.displayName ?? 'Usuario',
        isLawyer: userType == UserType.lawyer,
        parentReplyId: _replyingToId,
      );

      _replyController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToAuthor = null;
      });

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
        SnackBar(content: Text('Error al enviar respuesta: $e')),
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
        title: Text('Tema del foro'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Compartir'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 18),
                    SizedBox(width: 8),
                    Text('Reportar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Topic header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.topic.isPinned) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 12, color: Colors.orange),
                            SizedBox(width: 2),
                            Text('FIJADO', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    if (widget.topic.isLocked) ...[
                      Icon(Icons.lock, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                    ],
                  ],
                ),
                SizedBox(height: 8),
                
                Text(
                  widget.topic.title,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.0),
                
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: widget.topic.isLawyer ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        widget.topic.isLawyer ? Icons.verified : Icons.person,
                        size: 18,
                        color: widget.topic.isLawyer ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.topic.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.topic.isLawyer ? Colors.blue[700] : Colors.grey[800],
                              ),
                            ),
                            if (widget.topic.isLawyer) ...[
                              SizedBox(width: 4.0),
                              Icon(Icons.verified, size: 14, color: Colors.blue),
                            ],
                          ],
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(widget.topic.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text('${widget.topic.views}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            SizedBox(width: 12),
                            Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text('${widget.topic.repliesCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (widget.topic.tags.isNotEmpty) ...[
                  SizedBox(height: 12.0),
                  Wrap(
                    spacing: 6.0,
                    children: widget.topic.tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // Topic content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            child: Text(
              widget.topic.content,
              style: TextStyle(fontSize: 16.0, height: 1.5),
            ),
          ),
          
          Divider(),
          
          // Replies
          Expanded(
            child: StreamBuilder<List<ForumReply>>(
              stream: _forumService.getTopicReplies(widget.topic.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final replies = snapshot.data ?? [];

                if (replies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay respuestas aún',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '¡Sé el primero en responder!',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: replies.length,
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    return _buildReplyCard(replies[index], index + 1);
                  },
                );
              },
            ),
          ),
          
          // Reply input (only if topic is not locked)
          if (!widget.topic.isLocked) _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildReplyCard(ForumReply reply, int replyNumber) {
    final user = Provider.of<User?>(context);
    final isCurrentUser = reply.authorId == user?.uid;

    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#$replyNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 12),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: reply.isLawyer ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    reply.isLawyer ? Icons.verified : Icons.person,
                    size: 16,
                    color: reply.isLawyer ? Colors.blue : Colors.grey[600],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  reply.authorName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: reply.isLawyer ? Colors.blue[700] : Colors.grey[800],
                  ),
                ),
                if (reply.isLawyer) ...[
                  SizedBox(width: 4),
                  Icon(Icons.verified, size: 12, color: Colors.blue),
                ],
                Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleReplyAction(value, reply),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'reply',
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 16),
                          SizedBox(width: 8),
                          Text('Responder'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'like',
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up, size: 16),
                          SizedBox(width: 8),
                          Text('Me gusta'),
                        ],
                      ),
                    ),
                    if (isCurrentUser)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(reply.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            SizedBox(height: 12),
            
            if (reply.parentReplyId != null)
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border(left: BorderSide(color: Colors.blue, width: 3)),
                ),
                child: Text(
                  'Respondiendo a un mensaje anterior',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            
            Text(
              reply.content,
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text('${reply.likes}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _setReplyTo(reply),
                  icon: Icon(Icons.reply, size: 16),
                  label: Text('Responder'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToId != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Respondiendo a $_replyingToAuthor',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingToId = null;
                        _replyingToAuthor = null;
                      });
                    },
                    child: Icon(Icons.close, size: 16, color: Colors.blue),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: _replyingToId != null 
                        ? 'Responder a $_replyingToAuthor...'
                        : 'Escribe tu respuesta...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
              SizedBox(width: 8.0),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: _isLoading 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send),
                  color: Colors.white,
                  onPressed: _isLoading ? null : _sendReply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareTopic();
        break;
      case 'report':
        _reportTopic();
        break;
    }
  }

  void _handleReplyAction(String action, ForumReply reply) {
    switch (action) {
      case 'reply':
        _setReplyTo(reply);
        break;
      case 'like':
        _likeReply(reply);
        break;
      case 'delete':
        _deleteReply(reply);
        break;
    }
  }

  void _setReplyTo(ForumReply reply) {
    setState(() {
      _replyingToId = reply.id;
      _replyingToAuthor = reply.authorName;
    });
    
    // Focus on the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _likeReply(ForumReply reply) async {
    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) return;

      await _forumService.likeReply(reply.id, user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deleteReply(ForumReply reply) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar respuesta'),
          content: Text('¿Estás seguro de que quieres eliminar esta respuesta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _forumService.deleteReply(reply.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Respuesta eliminada')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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

  void _shareTopic() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de compartir en desarrollo')),
    );
  }

  void _reportTopic() {
    showDialog(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        
        return AlertDialog(
          title: Text('Reportar tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Por qué quieres reportar este tema?'),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Describe la razón...',
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
              onPressed: () {
                // Aquí implementarías la lógica para reportar
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reporte enviado. Gracias por tu colaboración.')),
                );
              },
              child: Text('Reportar'),
            ),
          ],
        );
      },
    );
  }
}