import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key, required this.post, required this.postId});

  final PostModel post;
  final String postId;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late int? _estimatedMinutes;
  late bool _anonymous;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.post.description);
    _estimatedMinutes = widget.post.estimatedMinutes;
    _anonymous = widget.post.anonymous;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{
        'description': _descCtrl.text.trim(),
        'anonymous': _anonymous,
      };
      if (_estimatedMinutes != null) {
        updates['estimatedMinutes'] = _estimatedMinutes;
      } else {
        updates['estimatedMinutes'] = FieldValue.delete();
      }

      await context.read<FirestoreService>().updatePost(widget.postId, updates);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await context.read<FirestoreService>().deletePost(widget.postId);
      if (mounted) {
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(); // Also pop the detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete. Check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descCtrl,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _estimatedMinutes,
                decoration: const InputDecoration(
                  labelText: 'Estimated time (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Not specified')),
                  ...([15, 30, 45, 60, 90, 120].map((m) =>
                      DropdownMenuItem(value: m, child: Text('$m min')))),
                ],
                onChanged: (v) => setState(() => _estimatedMinutes = v),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Post anonymously'),
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete post'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
