// lib/db/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';
import '../models/reply.dart';

class DatabaseHelper {
  // Singleton pattern – only one DB connection throughout the app lifecycle
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'offline_posts.db';
  static const int _dbVersion = 1;

  // Table names
  static const String tablePost = 'posts';
  static const String tableReply = 'replies';

  /// Returns the database, initializing it if not yet open.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens (or creates) the SQLite database file on the device.
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Called once when the database is first created.
  Future<void> _onCreate(Database db, int version) async {
    // Posts table
    await db.execute('''
      CREATE TABLE $tablePost (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        body       TEXT    NOT NULL,
        author     TEXT    NOT NULL DEFAULT 'Anonymous',
        likes      INTEGER NOT NULL DEFAULT 0,
        created_at TEXT    NOT NULL,
        updated_at TEXT    NOT NULL
      )
    ''');

    // Replies table – foreign-keyed to posts
    await db.execute('''
      CREATE TABLE $tableReply (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id    INTEGER NOT NULL,
        body       TEXT    NOT NULL,
        author     TEXT    NOT NULL DEFAULT 'Anonymous',
        likes      INTEGER NOT NULL DEFAULT 0,
        created_at TEXT    NOT NULL,
        FOREIGN KEY (post_id) REFERENCES $tablePost (id) ON DELETE CASCADE
      )
    ''');

    // Seed data so the app isn't empty on first launch
    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(tablePost, {
      'title': 'Welcome to Offline Posts Manager',
      'body':
          'This app works completely offline using SQLite. You can create, read, update and delete posts without any internet connection.',
      'author': 'Admin',
      'likes': 5,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert(tablePost, {
      'title': 'How SQLite Works in Flutter',
      'body':
          'SQLite stores data in a single file on the device. The sqflite package provides an async API so database calls never block the UI thread.',
      'author': 'Dev Team',
      'likes': 3,
      'created_at': now,
      'updated_at': now,
    });
  }

  // ─────────────────────────────────────────
  // POST CRUD
  // ─────────────────────────────────────────

  /// Read all posts, newest first.
  Future<List<Post>> getAllPosts() async {
    try {
      final db = await database;
      final maps = await db.query(tablePost, orderBy: 'created_at DESC');
      return maps.map(Post.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to load posts: $e');
    }
  }

  /// Read a single post by id.
  Future<Post?> getPost(int id) async {
    try {
      final db = await database;
      final maps =
          await db.query(tablePost, where: 'id = ?', whereArgs: [id], limit: 1);
      if (maps.isEmpty) return null;
      return Post.fromMap(maps.first);
    } catch (e) {
      throw DatabaseException('Failed to load post $id: $e');
    }
  }

  /// Insert a new post. Returns the new row's id.
  Future<int> insertPost(Post post) async {
    _validatePost(post);
    try {
      final db = await database;
      return await db.insert(
        tablePost,
        post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert post: $e');
    }
  }

  /// Update an existing post.
  Future<int> updatePost(Post post) async {
    if (post.id == null) throw DatabaseException('Cannot update a post without an id');
    _validatePost(post);
    try {
      final db = await database;
      final updated = post.copyWith(updatedAt: DateTime.now());
      return await db.update(
        tablePost,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update post ${post.id}: $e');
    }
  }

  /// Delete a post and all its replies.
  Future<int> deletePost(int id) async {
    try {
      final db = await database;
      // Replies are deleted via ON DELETE CASCADE, but we delete explicitly
      // as well for safety (some builds don't enable foreign keys by default).
      await db.delete(tableReply, where: 'post_id = ?', whereArgs: [id]);
      return await db.delete(tablePost, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete post $id: $e');
    }
  }

  /// Toggle like (+1) on a post.
  Future<void> likePost(int id) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE $tablePost SET likes = likes + 1 WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to like post $id: $e');
    }
  }

  // ─────────────────────────────────────────
  // REPLY CRUD
  // ─────────────────────────────────────────

  /// Get all replies for a specific post.
  Future<List<Reply>> getRepliesForPost(int postId) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableReply,
        where: 'post_id = ?',
        whereArgs: [postId],
        orderBy: 'created_at ASC',
      );
      return maps.map(Reply.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to load replies for post $postId: $e');
    }
  }

  /// Insert a new reply. Returns the new row's id.
  Future<int> insertReply(Reply reply) async {
    _validateReply(reply);
    try {
      final db = await database;
      return await db.insert(
        tableReply,
        reply.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert reply: $e');
    }
  }

  /// Delete a single reply.
  Future<int> deleteReply(int id) async {
    try {
      final db = await database;
      return await db.delete(tableReply, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete reply $id: $e');
    }
  }

  /// Toggle like (+1) on a reply.
  Future<void> likeReply(int id) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE $tableReply SET likes = likes + 1 WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to like reply $id: $e');
    }
  }

  // ─────────────────────────────────────────
  // Validation helpers
  // ─────────────────────────────────────────

  void _validatePost(Post post) {
    if (post.title.trim().isEmpty) {
      throw DatabaseException('Post title cannot be empty');
    }
    if (post.body.trim().isEmpty) {
      throw DatabaseException('Post body cannot be empty');
    }
    if (post.author.trim().isEmpty) {
      throw DatabaseException('Post author cannot be empty');
    }
  }

  void _validateReply(Reply reply) {
    if (reply.body.trim().isEmpty) {
      throw DatabaseException('Reply body cannot be empty');
    }
    if (reply.author.trim().isEmpty) {
      throw DatabaseException('Reply author cannot be empty');
    }
  }

  /// Close the database (call when the app is disposed).
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}

/// Custom exception so callers can catch DB-specific errors separately.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
