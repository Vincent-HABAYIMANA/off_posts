// lib/screens/post_form_screen.dart

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/post.dart';

class PostFormScreen extends StatefulWidget {
  /// If [post] is null, we are creating a new post; otherwise editing.
  final Post? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _authorCtrl;

  bool _isSaving = false;
  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.post?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.post?.body ?? '');
    _authorCtrl = TextEditingController(text: widget.post?.author ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated = widget.post!.copyWith(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          author: _authorCtrl.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _db.updatePost(updated);
      } else {
        final newPost = Post(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          author: _authorCtrl.text.trim().isEmpty ? 'Anonymous' : _authorCtrl.text.trim(),
        );
        await _db.insertPost(newPost);
      }
      if (mounted) Navigator.pop(context);
    } on DatabaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 3) return 'Title must be at least 3 characters';
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _authorCtrl,
              decoration: const InputDecoration(
                labelText: 'Author',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                hintText: 'Leave blank for Anonymous',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Content *',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Icon(Icons.article_outlined),
                ),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Content is required';
                if (v.trim().length < 10) return 'Content must be at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Save Changes' : 'Create Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
