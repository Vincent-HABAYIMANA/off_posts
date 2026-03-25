// lib/models/reply.dart

class Reply {
  final int? id;
  final int postId;
  final String body;
  final String author;
  final int likes;
  final DateTime createdAt;

  Reply({
    this.id,
    required this.postId,
    required this.body,
    required this.author,
    this.likes = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'post_id': postId,
      'body': body,
      'author': author,
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reply.fromMap(Map<String, dynamic> map) {
    return Reply(
      id: map['id'] as int?,
      postId: map['post_id'] as int? ?? 0,
      body: map['body'] as String? ?? '',
      author: map['author'] as String? ?? 'Anonymous',
      likes: map['likes'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Reply copyWith({
    int? id,
    int? postId,
    String? body,
    String? author,
    int? likes,
    DateTime? createdAt,
  }) {
    return Reply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      body: body ?? this.body,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
