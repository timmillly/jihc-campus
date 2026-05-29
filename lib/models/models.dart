import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'event' or 'news'
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? eventDate;
  final String? imageUrl;
  final String location;
  final int likes;
  final List<String> likedBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.eventDate,
    this.imageUrl,
    required this.location,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'news',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventDate: (data['eventDate'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
      location: data['location'] ?? '',
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'imageUrl': imageUrl,
      'location': location,
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? eventDate,
    String? imageUrl,
    String? location,
    int? likes,
    List<String>? likedBy,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      eventDate: eventDate ?? this.eventDate,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
