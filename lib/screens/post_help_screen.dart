import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../widgets/location_picker_map.dart';

class PostHelpScreen extends StatefulWidget {
  const PostHelpScreen({super.key});

  @override
  State<PostHelpScreen> createState() => _PostHelpScreenState();
}

class _PostHelpScreenState extends State<PostHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  PostType _type = PostType.request;
  bool _anonymous = false;
  double _radiusKm = 5;
  int? _estimatedMinutes;
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 24));
  bool _submitting = false;

  // Location state
  GeoPoint? _gpsLocation; // Actual device GPS
  GeoPoint? _selectedLocation; // User-picked pin on map
  bool _loadingLocation = false;

  // Poster info (for anonymous posts that still show gender/age)
  String? _posterGender;
  String? _posterAgeRange;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _loadingLocation = true);

    // First, try to load saved location from Firestore as a quick fallback
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();
        final savedLocation = data?['location'] as GeoPoint?;
        _posterGender = data?['gender'] as String?;
        _posterAgeRange = data?['ageRange'] as String?;
        if (savedLocation != null && mounted) {
          setState(() {
            _gpsLocation = savedLocation;
            _selectedLocation = savedLocation;
          });
        }
      } catch (_) {}
    }

    // Then try to get fresh GPS location
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.location_on, size: 40),
            title: const Text('Share your location'),
            content: const Text(
              'We need your location to show your post to nearby neighbors. '
              'Only your approximate area is shared — never your exact address.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Allow location'),
              ),
            ],
          ),
        );
        if (shouldRequest != true) return;
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // If we already have a saved location, don't show the error dialog
        if (_selectedLocation != null) return;
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.location_off, size: 40),
            title: const Text('Location access needed'),
            content: const Text(
              'Location access was permanently denied. '
              'Please enable it in your device Settings to post locally.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (_selectedLocation != null) return;
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.location_off, size: 40),
            title: const Text('Location services off'),
            content: const Text(
              'Please turn on location services to post locally.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final geoPoint = GeoPoint(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _gpsLocation = geoPoint;
          _selectedLocation = geoPoint;
        });
      }

      // Save fresh GPS location to user profile for future fallback
      if (uid != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'location': geoPoint}).catchError((_) {});
      }
    } catch (_) {
      // GPS failed — we may still have the saved location from above
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onLocationChanged(GeoPoint newLocation) {
    setState(() => _selectedLocation = newLocation);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      final location = _selectedLocation;
      if (location == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please set a location for your post using the map or search.'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        setState(() => _submitting = false);
        return;
      }

      final post = PostModel(
        type: _type,
        description: _descController.text.trim(),
        userId: uid,
        location: location,
        radius: _radiusKm,
        global: false,
        expiresAt: _expiresAt,
        anonymous: _anonymous,
        estimatedMinutes: _estimatedMinutes,
        posterGender: _posterGender,
        posterAgeRange: _posterAgeRange,
      );

      await context.read<FirestoreService>().createPost(post);
      if (!mounted) return;
      context.read<AnalyticsService>().logPostCreated(
        type: _type.name,
        isGlobal: false,
        radius: _radiusKm,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == PostType.request
                ? 'Request published! Neighbors near that location will see it.'
                : 'Offer published! Neighbors near that location will see it.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _descController.clear();
      setState(() {
        _selectedLocation = _gpsLocation;
      });

      // Contextually request notification permission after first post
      if (mounted) {
        final notif = context.read<NotificationService>();
        final granted =
            await notif.requestPermissionWithRationale(context);
        if (granted && mounted) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) await notif.saveToken(uid);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post. Check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              const SizedBox(height: 8),
              // Map section
              if (_loadingLocation)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selectedLocation != null)
                LocationPickerMap(
                  initialLocation: _selectedLocation!,
                  radiusKm: _radiusKm,
                  onLocationChanged: _onLocationChanged,
                  actualGpsLocation: _gpsLocation,
                )
              else
                OutlinedButton.icon(
                  onPressed: _initLocation,
                  icon: const Icon(Icons.map),
                  label: const Text('Set location'),
                ),
              const SizedBox(height: 8),
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
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
