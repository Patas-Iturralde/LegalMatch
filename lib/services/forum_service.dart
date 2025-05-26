import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CATEGORÍAS
  
  // Obtener todas las categorías
  Stream<List<ForumCategory>> getCategories() {
    return _firestore
        .collection('forum_categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumCategory.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Crear una categoría
  Future<void> createCategory({
    required String name,
    required String description,
    required String iconName,
  }) async {
    final category = ForumCategory(
      id: '',
      name: name,
      description: description,
      iconName: iconName,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('forum_categories').add(category.toMap());
  }

  // TEMAS
  
  // Obtener temas por categoría
  Stream<List<ForumTopic>> getTopicsByCategory(String categoryId, String sortBy) {
    Query query = _firestore
        .collection('forum_topics')
        .where('categoryId', isEqualTo: categoryId);

    // Aplicar ordenamiento
    switch (sortBy) {
      case 'lastActivity':
        query = query.orderBy('lastActivity', descending: true);
        break;
      case 'created':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'replies':
        query = query.orderBy('repliesCount', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumTopic.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Crear un nuevo tema
  Future<String> createTopic({
    required String categoryId,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required bool isLawyer,
    List<String> tags = const [],
  }) async {
    final topic = ForumTopic(
      id: '',
      categoryId: categoryId,
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      isLawyer: isLawyer,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      tags: tags,
      views: 0, // Inicializar explícitamente
      repliesCount: 0, // Inicializar explícitamente
      isPinned: false, // Inicializar explícitamente
      isLocked: false, // Inicializar explícitamente
    );

    final docRef = await _firestore.collection('forum_topics').add(topic.toMap());

    // Incrementar contador de temas en la categoría
    try {
      await _firestore.collection('forum_categories').doc(categoryId).update({
        'topicsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error al incrementar contador de categoría: $e');
    }

    return docRef.id;
  }

  // Buscar temas
  Future<List<ForumTopic>> searchTopics(String query) async {
    final snapshot = await _firestore.collection('forum_topics').get();

    final topics = snapshot.docs
        .map((doc) => ForumTopic.fromMap(doc.data(), doc.id))
        .where((topic) {
      final searchQuery = query.toLowerCase();
      return topic.title.toLowerCase().contains(searchQuery) ||
             topic.content.toLowerCase().contains(searchQuery) ||
             topic.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
    }).toList();

    return topics;
  }

  // Incrementar vistas de un tema
  Future<void> incrementTopicViews(String topicId) async {
    try {
      await _firestore.collection('forum_topics').doc(topicId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error al incrementar vistas del tema: $e');
      // No lanzar error para que no afecte la navegación
    }
  }

  // Obtener tema por ID
  Future<ForumTopic?> getTopicById(String topicId) async {
    final doc = await _firestore.collection('forum_topics').doc(topicId).get();
    if (doc.exists) {
      return ForumTopic.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Eliminar tema
  Future<void> deleteTopic(String topicId) async {
    // Obtener el tema para saber su categoría
    final topicDoc = await _firestore.collection('forum_topics').doc(topicId).get();
    if (topicDoc.exists) {
      final topicData = topicDoc.data()!;
      final categoryId = topicData['categoryId'];

      // Eliminar el tema
      await _firestore.collection('forum_topics').doc(topicId).delete();

      // Decrementar contador de temas en la categoría
      await _firestore.collection('forum_categories').doc(categoryId).update({
        'topicsCount': FieldValue.increment(-1),
      });

      // Eliminar todas las respuestas del tema
      final repliesQuery = await _firestore
          .collection('forum_replies')
          .where('topicId', isEqualTo: topicId)
          .get();

      final batch = _firestore.batch();
      for (final doc in repliesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // RESPUESTAS
  
  // Obtener respuestas de un tema
  Stream<List<ForumReply>> getTopicReplies(String topicId) {
    return _firestore
        .collection('forum_replies')
        .where('topicId', isEqualTo: topicId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumReply.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Agregar una respuesta
  Future<void> addReply({
    required String topicId,
    required String content,
    required String authorId,
    required String authorName,
    required bool isLawyer,
    String? parentReplyId,
  }) async {
    final reply = ForumReply(
      id: '',
      topicId: topicId,
      content: content,
      authorId: authorId,
      authorName: authorName,
      isLawyer: isLawyer,
      createdAt: DateTime.now(),
      parentReplyId: parentReplyId,
      likes: 0, // Inicializar explícitamente
      likedBy: [], // Inicializar explícitamente
    );

    await _firestore.collection('forum_replies').add(reply.toMap());

    // Actualizar contador de respuestas y última actividad del tema
    try {
      await _firestore.collection('forum_topics').doc(topicId).update({
        'repliesCount': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });
    } catch (e) {
      print('Error al actualizar estadísticas del tema: $e');
    }
  }

  // Dar like a una respuesta
  Future<void> likeReply(String replyId, String userId) async {
    final replyRef = _firestore.collection('forum_replies').doc(replyId);
    
    await _firestore.runTransaction((transaction) async {
      final replyDoc = await transaction.get(replyRef);
      if (replyDoc.exists) {
        final data = replyDoc.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        
        if (likedBy.contains(userId)) {
          // Usuario ya dio like, quitar like
          likedBy.remove(userId);
          transaction.update(replyRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': likedBy,
          });
        } else {
          // Usuario no ha dado like, agregar like
          likedBy.add(userId);
          transaction.update(replyRef, {
            'likes': FieldValue.increment(1),
            'likedBy': likedBy,
          });
        }
      }
    });
  }

  // Eliminar una respuesta
  Future<void> deleteReply(String replyId) async {
    // Obtener la respuesta para saber su tema
    final replyDoc = await _firestore.collection('forum_replies').doc(replyId).get();
    if (replyDoc.exists) {
      final replyData = replyDoc.data()!;
      final topicId = replyData['topicId'];

      // Eliminar la respuesta
      await _firestore.collection('forum_replies').doc(replyId).delete();

      // Decrementar contador de respuestas del tema
      await _firestore.collection('forum_topics').doc(topicId).update({
        'repliesCount': FieldValue.increment(-1),
      });
    }
  }

  // FUNCIONES DE MODERACIÓN
  
  // Fijar/desfijar tema
  Future<void> pinTopic(String topicId, bool isPinned) async {
    await _firestore.collection('forum_topics').doc(topicId).update({
      'isPinned': isPinned,
    });
  }

  // Bloquear/desbloquear tema
  Future<void> lockTopic(String topicId, bool isLocked) async {
    await _firestore.collection('forum_topics').doc(topicId).update({
      'isLocked': isLocked,
    });
  }

  // ESTADÍSTICAS
  
  // Obtener estadísticas del foro
  Future<Map<String, int>> getForumStats() async {
    final topicsSnapshot = await _firestore.collection('forum_topics').get();
    final repliesSnapshot = await _firestore.collection('forum_replies').get();
    final categoriesSnapshot = await _firestore.collection('forum_categories').get();

    return {
      'topics': topicsSnapshot.docs.length,
      'replies': repliesSnapshot.docs.length,
      'categories': categoriesSnapshot.docs.length,
    };
  }

  // Obtener temas más populares
  Future<List<ForumTopic>> getPopularTopics({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('forum_topics')
        .orderBy('views', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return ForumTopic.fromMap(doc.data(), doc.id);
    }).toList();
  }

  // Obtener temas recientes
  Future<List<ForumTopic>> getRecentTopics({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('forum_topics')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return ForumTopic.fromMap(doc.data(), doc.id);
    }).toList();
  }

  // INICIALIZACIÓN DE DATOS
  
  // Inicializar categorías por defecto
  Future<void> initializeDefaultCategories() async {
    final categoriesSnapshot = await _firestore.collection('forum_categories').get();
    
    if (categoriesSnapshot.docs.isEmpty) {
      final defaultCategories = [
        {
          'name': 'Derecho Civil',
          'description': 'Consultas sobre contratos, propiedad, daños y responsabilidad civil',
          'iconName': 'gavel',
        },
        {
          'name': 'Derecho Penal',
          'description': 'Temas relacionados con delitos, procesos penales y defensa criminal',
          'iconName': 'security',
        },
        {
          'name': 'Derecho Laboral',
          'description': 'Derechos de trabajadores, despidos, contratos laborales',
          'iconName': 'work',
        },
        {
          'name': 'Derecho Familiar',
          'description': 'Divorcios, custodia, pensiones alimenticias, adopciones',
          'iconName': 'family',
        },
        {
          'name': 'Derecho Mercantil',
          'description': 'Empresas, sociedades, comercio, quiebras',
          'iconName': 'business',
        },
        {
          'name': 'Derecho Inmobiliario',
          'description': 'Compraventa, arrendamientos, propiedad horizontal',
          'iconName': 'home',
        },
        {
          'name': 'Derecho Constitucional',
          'description': 'Derechos fundamentales, recursos de amparo, derecho público',
          'iconName': 'account_balance',
        },
        {
          'name': 'Consultas Generales',
          'description': 'Preguntas generales sobre derecho y orientación legal',
          'iconName': 'help',
        },
      ];

      final batch = _firestore.batch();
      for (final categoryData in defaultCategories) {
        final category = ForumCategory(
          id: '',
          name: categoryData['name'] as String,
          description: categoryData['description'] as String,
          iconName: categoryData['iconName'] as String,
          createdAt: DateTime.now(),
        );
        
        final docRef = _firestore.collection('forum_categories').doc();
        batch.set(docRef, category.toMap());
      }
      
      await batch.commit();
    }
  }
}