import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/virtual_classroom.dart';

class VirtualClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo recurso
  Future<void> createResource({
    required String title,
    required String description,
    required String type,
    required String url,
    required String authorId,
    required String authorName,
    required String category,
    List<String> tags = const [],
  }) async {
    final resource = VirtualResource(
      id: '',
      title: title,
      description: description,
      type: type,
      url: url,
      authorId: authorId,
      authorName: authorName,
      category: category,
      createdAt: DateTime.now(),
      isActive: true,
      tags: tags,
    );

    await _firestore.collection('virtual_resources').add(resource.toMap());
  }

  // Obtener recursos por categoría
  Stream<List<VirtualResource>> getResourcesByCategory(String category) {
    return _firestore
        .collection('virtual_resources')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VirtualResource.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener todos los recursos activos
  Stream<List<VirtualResource>> getAllResources() {
    return _firestore
        .collection('virtual_resources')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VirtualResource.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Buscar recursos por título o descripción
  Future<List<VirtualResource>> searchResources(String query) async {
    final snapshot = await _firestore
        .collection('virtual_resources')
        .where('isActive', isEqualTo: true)
        .get();

    final resources = snapshot.docs
        .map((doc) => VirtualResource.fromMap(doc.data(), doc.id))
        .where((resource) {
      final searchQuery = query.toLowerCase();
      return resource.title.toLowerCase().contains(searchQuery) ||
             resource.description.toLowerCase().contains(searchQuery) ||
             resource.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
    }).toList();

    return resources;
  }

  // Incrementar vistas
  Future<void> incrementViews(String resourceId) async {
    await _firestore.collection('virtual_resources').doc(resourceId).update({
      'views': FieldValue.increment(1),
    });
  }

  // Incrementar likes
  Future<void> incrementLikes(String resourceId) async {
    await _firestore.collection('virtual_resources').doc(resourceId).update({
      'likes': FieldValue.increment(1),
    });
  }

  // Eliminar recurso
  Future<void> deleteResource(String resourceId) async {
    await _firestore.collection('virtual_resources').doc(resourceId).update({
      'isActive': false,
    });
  }

  // Actualizar recurso
  Future<void> updateResource(VirtualResource resource) async {
    await _firestore.collection('virtual_resources').doc(resource.id).update(resource.toMap());
  }

  // Agregar comentario a un recurso
  Future<void> addComment({
    required String resourceId,
    required String userId,
    required String userName,
    required String comment,
  }) async {
    final commentData = ResourceComment(
      id: '',
      resourceId: resourceId,
      userId: userId,
      userName: userName,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('resource_comments').add(commentData.toMap());
  }

  // Obtener comentarios de un recurso
  Stream<List<ResourceComment>> getResourceComments(String resourceId) {
    return _firestore
        .collection('resource_comments')
        .where('resourceId', isEqualTo: resourceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ResourceComment.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener recursos por autor
  Stream<List<VirtualResource>> getResourcesByAuthor(String authorId) {
    return _firestore
        .collection('virtual_resources')
        .where('authorId', isEqualTo: authorId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VirtualResource.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener estadísticas de recursos
  Future<Map<String, int>> getResourceStats() async {
    final snapshot = await _firestore
        .collection('virtual_resources')
        .where('isActive', isEqualTo: true)
        .get();

    final stats = <String, int>{
      'total': snapshot.docs.length,
      'documents': 0,
      'videos': 0,
      'links': 0,
      'forms': 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] ?? 'link';
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return stats;
  }
}