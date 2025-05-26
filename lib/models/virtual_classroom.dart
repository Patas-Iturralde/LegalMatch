import 'package:cloud_firestore/cloud_firestore.dart';

class VirtualResource {
  final String id;
  final String title;
  final String description;
  final String type; // 'document', 'video', 'form', 'link'
  final String url;
  final String authorId;
  final String authorName;
  final String category;
  final DateTime createdAt;
  final bool isActive;
  final List<String> tags;
  final int views;
  final int likes;

  VirtualResource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.createdAt,
    required this.isActive,
    this.tags = const [],
    this.views = 0,
    this.likes = 0,
  });

  factory VirtualResource.fromMap(Map<String, dynamic> data, String id) {
    return VirtualResource(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'link',
      url: data['url'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      category: data['category'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'authorId': authorId,
      'authorName': authorName,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'tags': tags,
      'views': views,
      'likes': likes,
    };
  }
}

class ResourceComment {
  final String id;
  final String resourceId;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  ResourceComment({
    required this.id,
    required this.resourceId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory ResourceComment.fromMap(Map<String, dynamic> data, String id) {
    return ResourceComment(
      id: id,
      resourceId: data['resourceId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}