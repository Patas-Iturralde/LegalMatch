import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/forum.dart';
import '../../services/forum_service.dart';
import 'forum_topic_detail_screen.dart';

// Pantalla de búsqueda en el foro
class ForumSearchScreen extends StatefulWidget {
  final String query;

  ForumSearchScreen({required this.query});

  @override
  _ForumSearchScreenState createState() => _ForumSearchScreenState();
}

class _ForumSearchScreenState extends State<ForumSearchScreen> {
  final ForumService _forumService = ForumService();
  List<ForumTopic> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _forumService.searchTopics(widget.query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en la búsqueda: $e')),
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
        title: Text('Resultados: "${widget.query}"'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No se encontraron resultados',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Intenta con otros términos de búsqueda',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  padding: EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    return _buildTopicCard(_searchResults[index]);
                  },
                ),
    );
  }

  Widget _buildTopicCard(ForumTopic topic) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumTopicDetailScreen(topic: topic),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                topic.content,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.0),
              Row(
                children: [
                  Text(
                    topic.authorName,
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                  if (topic.isLawyer) ...[
                    SizedBox(width: 4.0),
                    Icon(Icons.verified, size: 12, color: Colors.blue),
                  ],
                  Spacer(),
                  Text(
                    '${topic.repliesCount} respuestas',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}