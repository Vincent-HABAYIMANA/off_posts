// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/post.dart';
import '../models/reply.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _db = DatabaseHelper();
  Post? _post;
  List<Reply> _replies = [];
  bool _isLoading = true;
  String? _errorMessage;

  final _replyBodyController = TextEditingController();
  final _replyAuthorController = TextEditingController();
  bool _submittingReply = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _replyBodyController.dispose();
    _replyAuthorController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final post = await _db.getPost(widget.postId);
      if (post == null) {
        setState(() => _errorMessage = 'Post not found.');
        return;
      }
      final replies = await _db.getRepliesForPost(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _replies = replies;
        });
      }
    } on DatabaseException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _likePost() async {
    try {
      await _db.likePost(widget.postId);
      await _loadData();
    } on DatabaseException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  Future<void> _likeReply(Reply reply) async {
    try {
      await _db.likeReply(reply.id!);
      await _loadData();
    } on DatabaseException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  Future<void> _submitReply() async {
    final body = _replyBodyController.text.trim();
    final author = _replyAuthorController.text.trim();
    if (body.isEmpty) {
      _showSnack('Reply cannot be empty', isError: true);
      return;
    }
    setState(() => _submittingReply = true);
    try {
      await _db.insertReply(Reply(
        postId: widget.postId,
        body: body,
        author: author.isEmpty ? 'Anonymous' : author,
      ));
      _replyBodyController.clear();
      _replyAuthorController.clear();
      _showSnack('Reply added!');
      await _loadData();
    } on DatabaseException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submittingReply = false);
    }
  }

  Future<void> _deleteReply(Reply reply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _db.deleteReply(reply.id!);
        _showSnack('Reply deleted');
        await _loadData();
      } on DatabaseException catch (e) {
        _showSnack(e.message, isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (_post != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Post',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostFormScreen(post: _post)),
                );
                await _loadData();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final post = _post!;
    final fmt = DateFormat('MMM d, yyyy – HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Post Card ───────────────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(post.author, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(fmt.format(post.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Divider(height: 24),
                Text(post.body, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                // Like button for post
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _likePost,
                      icon: Icon(
                        post.likes > 0 ? Icons.favorite : Icons.favorite_border,
                        color: post.likes > 0 ? Colors.red : null,
                      ),
                      label: Text('${post.likes} ${post.likes == 1 ? 'Like' : 'Likes'}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Replies Section ─────────────────────────────────────────────────
        Text('${_replies.length} ${_replies.length == 1 ? 'Reply' : 'Replies'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._replies.map((reply) => _ReplyCard(
              reply: reply,
              onLike: () => _likeReply(reply),
              onDelete: () => _deleteReply(reply),
            )),
        const SizedBox(height: 24),

        // ── Add Reply Form ──────────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a Reply', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _replyAuthorController,
                  decoration: const InputDecoration(
                    labelText: 'Your name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _replyBodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Write a reply…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submittingReply ? null : _submitReply,
                    icon: _submittingReply
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: const Text('Post Reply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Reply Card Widget ───────────────────────────────────────────────────────

class _ReplyCard extends StatelessWidget {
  final Reply reply;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _ReplyCard({required this.reply, required this.onLike, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy – HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    reply.author.isNotEmpty ? reply.author[0].toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reply.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(fmt.format(reply.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                // Like reply
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        reply.likes > 0 ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: reply.likes > 0 ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      Text('${reply.likes}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(reply.body, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
