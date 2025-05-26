import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/forum.dart';
import '../../services/forum_service.dart';
import '../../services/auth_service.dart';
import 'forum_topic_detail_screen.dart';
import 'create_topic_screen.dart';

// Pantalla de temas por categoría
class ForumTopicsScreen extends StatefulWidget {
  final ForumCategory category;

  ForumTopicsScreen({required this.category});

  @override
  _ForumTopicsScreenState createState() => _ForumTopicsScreenState();
}

class _ForumTopicsScreenState extends State<ForumTopicsScreen> {
  final ForumService _forumService = ForumService();
  String _sortBy = 'lastActivity'; // 'lastActivity', 'created', 'replies'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'lastActivity',
                child: Text('Ordenar por actividad'),
              ),
              PopupMenuItem(
                value: 'created',
                child: Text('Ordenar por fecha'),
              ),
              PopupMenuItem(
                value: 'replies',
                child: Text('Ordenar por respuestas'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ForumTopic>>(
        stream: _forumService.getTopicsByCategory(widget.category.id, _sortBy),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final topics = snapshot.data ?? [];

          if (topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.topic, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay temas en esta categoría',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _createTopic(),
                    child: Text('Crear el primer tema'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: topics.length,
            padding: EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              return _buildTopicCard(topics[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTopic,
        child: Icon(Icons.add),
        tooltip: 'Crear nuevo tema',
      ),
    );
  }

  Widget _buildTopicCard(ForumTopic topic) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _openTopic(topic),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (topic.isPinned)
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
                  if (topic.isPinned) SizedBox(width: 8),
                  if (topic.isLocked)
                    Icon(Icons.lock, size: 16, color: Colors.red),
                  if (topic.isLocked) SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic.title,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              
              Text(
                topic.content,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (topic.tags.isNotEmpty) ...[
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 4.0,
                  children: topic.tags.take(3).map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              SizedBox(height: 12.0),
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: topic.isLawyer ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    child: Icon(
                      topic.isLawyer ? Icons.verified : Icons.person,
                      size: 14,
                      color: topic.isLawyer ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    topic.authorName,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: topic.isLawyer ? Colors.blue[700] : Colors.grey[700],
                    ),
                  ),
                  if (topic.isLawyer) ...[
                    SizedBox(width: 4.0),
                    Icon(Icons.verified, size: 12, color: Colors.blue),
                  ],
                  Spacer(),
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text('${topic.views}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(width: 12.0),
                  Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4.0),
                  Text('${topic.repliesCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              
              SizedBox(height: 8.0),
              
              Row(
                children: [
                  Text(
                    'Creado: ${DateFormat('dd/MM/yyyy').format(topic.createdAt)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Spacer(),
                  Text(
                    'Última actividad: ${_formatLastActivity(topic.lastActivity)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTopic(ForumTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumTopicDetailScreen(topic: topic),
      ),
    );
  }

  void _createTopic() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTopicScreen(categoryId: widget.category.id),
      ),
    );
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minutos';
    } else {
      return 'hace un momento';
    }
  }
}