import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class PostHelpScreen extends StatefulWidget {
  const PostHelpScreen({super.key});

  @override
  State<PostHelpScreen> createState() => _PostHelpScreenState();
}

class _PostHelpScreenState extends State<PostHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  PostType _type = PostType.request;
  bool _global = false;
  bool _anonymous = false;
  double _radiusKm = 5;
  int? _estimatedMinutes;
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 24));

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<GeoPoint?> _getLocation() async {
    final ok = await Geolocator.checkPermission();
    if (ok == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final pos = await Geolocator.getCurrentPosition();
    return GeoPoint(pos.latitude, pos.longitude);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    GeoPoint? location;
    if (!_global) {
      location = await _getLocation();
      if (location == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location needed for local posts')),
        );
        return;
      }
    }

    final post = PostModel(
      type: _type,
      description: _descController.text.trim(),
      userId: uid,
      location: location,
      radius: _radiusKm,
      global: _global,
      expiresAt: _expiresAt,
      anonymous: _anonymous,
      estimatedMinutes: _estimatedMinutes,
    );

    await context.read<FirestoreService>().createPost(post);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created')),
      );
      _descController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Micro-Help')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<PostType>(
                segments: const [
                  ButtonSegment(
                    value: PostType.request,
                    icon: Icon(Icons.help_outline),
                    label: Text('Request'),
                  ),
                  ButtonSegment(
                    value: PostType.offer,
                    icon: Icon(Icons.volunteer_activism),
                    label: Text('Offer'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What do you need or offer?',
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
                title: const Text('Global (visible to everyone)'),
                value: _global,
                onChanged: (v) => setState(() => _global = v),
              ),
              if (!_global) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Radius: ${_radiusKm.toStringAsFixed(0)} km'),
                ),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_radiusKm.toStringAsFixed(0)} km',
                  onChanged: (v) => setState(() => _radiusKm = v),
                ),
              ],
              SwitchListTile(
                title: const Text('Post anonymously'),
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expires'),
                subtitle: Text(
                  '${_expiresAt.day}/${_expiresAt.month}/${_expiresAt.year} ${_expiresAt.hour}:00',
                ),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiresAt,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_expiresAt),
                    );
                    if (time != null) {
                      setState(() => _expiresAt = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          ));
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
