import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/forum.dart';
import '../../services/forum_service.dart';
import '../../services/auth_service.dart';
import 'forum_topics_screen.dart';
import 'forum_search_screen.dart';
import 'create_topic_screen.dart';

class ForumScreen extends StatefulWidget {
  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Inicializar categorías por defecto si no existen
    _forumService.initializeDefaultCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foro Jurídico'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'popular',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 18),
                    SizedBox(width: 8),
                    Text('Temas populares'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 8),
                    Text('Temas recientes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 8),
                    Text('Estadísticas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ForumCategory>>(
        stream: _forumService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando foro...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Inicializando foro...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Las categorías se están creando',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header con estadísticas
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Categorías', categories.length.toString(), Icons.category, Colors.blue),
                        _buildStatCard('Temas', _getTotalTopics(categories).toString(), Icons.topic, Colors.green),
                        _buildStatCard('Activos', 'Hoy', Icons.trending_up, Colors.orange),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bienvenido al foro jurídico. Aquí puedes hacer consultas y participar en discusiones legales.',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de categorías
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  padding: EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(categories[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTopicDialog(),
        icon: Icon(Icons.add),
        label: Text('Nuevo Tema'),
        tooltip: 'Crear nuevo tema',
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ForumCategory category) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _openCategory(category),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  _getCategoryIcon(category.iconName),
                  color: Theme.of(context).primaryColor,
                  size: 28.0,
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.0,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${category.topicsCount} temas',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Creado: ${DateFormat('dd/MM/yyyy').format(category.createdAt)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.0),
              Column(
                children: [
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                  SizedBox(height: 4),
                  if (category.topicsCount > 0)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(ForumCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumTopicsScreen(category: category),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final searchController = TextEditingController();
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('Buscar en el foro'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar temas, contenido, etiquetas...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForumSearchScreen(
                          query: value.trim(),
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 12),
              Text(
                'Puedes buscar por título, contenido o etiquetas',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                if (searchController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForumSearchScreen(
                        query: searchController.text.trim(),
                      ),
                    ),
                  );
                }
              },
              child: Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateTopicDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTopicScreen(),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'popular':
        _showPopularTopics();
        break;
      case 'recent':
        _showRecentTopics();
        break;
      case 'stats':
        _showForumStats();
        break;
    }
  }

  void _showPopularTopics() async {
    try {
      final popularTopics = await _forumService.getPopularTopics(limit: 10);
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange),
                SizedBox(width: 8),
                Text('Temas Populares'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: popularTopics.isEmpty
                  ? Center(child: Text('No hay temas populares aún'))
                  : ListView.builder(
                      itemCount: popularTopics.length,
                      itemBuilder: (context, index) {
                        final topic = popularTopics[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            child: Text('${index + 1}', style: TextStyle(color: Colors.orange[700])),
                          ),
                          title: Text(
                            topic.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('${topic.views} vistas • ${topic.repliesCount} respuestas'),
                          onTap: () {
                            Navigator.pop(context);
                            // Navegar al tema
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar temas populares: $e')),
      );
    }
  }

  void _showRecentTopics() async {
    try {
      final recentTopics = await _forumService.getRecentTopics(limit: 10);
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.access_time, color: Colors.green),
                SizedBox(width: 8),
                Text('Temas Recientes'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: recentTopics.isEmpty
                  ? Center(child: Text('No hay temas recientes'))
                  : ListView.builder(
                      itemCount: recentTopics.length,
                      itemBuilder: (context, index) {
                        final topic = recentTopics[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: topic.isLawyer ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            child: Icon(
                              topic.isLawyer ? Icons.verified : Icons.person,
                              color: topic.isLawyer ? Colors.blue : Colors.grey[600],
                            ),
                          ),
                          title: Text(
                            topic.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('${topic.authorName} • ${DateFormat('dd/MM HH:mm').format(topic.createdAt)}'),
                          onTap: () {
                            Navigator.pop(context);
                            // Navegar al tema
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar temas recientes: $e')),
      );
    }
  }

  void _showForumStats() async {
    try {
      final stats = await _forumService.getForumStats();
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text('Estadísticas del Foro'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow('Categorías', '${stats['categories'] ?? 0}', Icons.category),
                _buildStatRow('Temas totales', '${stats['topics'] ?? 0}', Icons.topic),
                _buildStatRow('Respuestas totales', '${stats['replies'] ?? 0}', Icons.reply),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El foro está creciendo cada día con más participación de la comunidad legal.',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14)),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalTopics(List<ForumCategory> categories) {
    return categories.fold(0, (sum, category) => sum + category.topicsCount);
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'gavel':
        return Icons.gavel;
      case 'business':
        return Icons.business;
      case 'family':
        return Icons.family_restroom;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'account_balance':
        return Icons.account_balance;
      case 'security':
        return Icons.security;
      case 'public':
        return Icons.public;
      case 'help':
        return Icons.help;
      default:
        return Icons.forum;
    }
  }
}