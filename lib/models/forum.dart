import 'package:cloud_firestore/cloud_firestore.dart';

class ForumCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int topicsCount;
  final DateTime createdAt;

  ForumCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.topicsCount = 0,
    required this.createdAt,
  });

  factory ForumCategory.fromMap(Map<String, dynamic> data, String id) {
    return ForumCategory(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'forum',
      topicsCount: data['topicsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'topicsCount': topicsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ForumTopic {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final bool isLawyer;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isPinned;
  final bool isLocked;
  final int repliesCount;
  final int views;
  final List<String> tags;

  ForumTopic({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.isLawyer,
    required this.createdAt,
    required this.lastActivity,
    this.isPinned = false,
    this.isLocked = false,
    this.repliesCount = 0,
    this.views = 0,
    this.tags = const [],
  });

  factory ForumTopic.fromMap(Map<String, dynamic> data, String id) {
    return ForumTopic(
      id: id,
      categoryId: data['categoryId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      isLawyer: data['isLawyer'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
      isPinned: data['isPinned'] ?? false,
      isLocked: data['isLocked'] ?? false,
      repliesCount: data['repliesCount'] ?? 0,
      views: data['views'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'isLawyer': isLawyer,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'isPinned': isPinned,
      'isLocked': isLocked,
      'repliesCount': repliesCount,
      'views': views,
      'tags': tags,
    };
  }
}

class ForumReply {
  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  final bool isLawyer;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final String? parentReplyId; // Para respuestas anidadas

  ForumReply({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.isLawyer,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.parentReplyId,
  });

  factory ForumReply.fromMap(Map<String, dynamic> data, String id) {
    return ForumReply(
      id: id,
      topicId: data['topicId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      isLawyer: data['isLawyer'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentReplyId: data['parentReplyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'isLawyer': isLawyer,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
      'parentReplyId': parentReplyId,
    };
  }
}