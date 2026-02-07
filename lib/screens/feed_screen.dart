import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/preferences_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  GeoPoint? _userLocation;
  bool _locationLoading = true;
  late bool _showGlobal;
  late double _localRadiusKm;
  Set<String> _blockedUsers = {};

  @override
  void initState() {
    super.initState();
    final prefs = context.read<PreferencesService>();
    _showGlobal = prefs.showGlobalPosts;
    _localRadiusKm = prefs.localRadiusKm;
    _loadUserLocation();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final blocked =
          await context.read<FirestoreService>().getBlockedUsers(uid);
      if (mounted) setState(() => _blockedUsers = blocked.toSet());
    } catch (_) {}
  }

  Future<void> _loadUserLocation() async {
    try {
      // First try to get location from the user's Firestore profile.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final loc = doc.data()?['location'] as GeoPoint?;
        if (loc != null) {
          if (mounted) setState(() { _userLocation = loc; _locationLoading = false; });
          return;
        }
      }

      // Fall back to device GPS.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = GeoPoint(pos.latitude, pos.longitude);
          _locationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  List<_PostWithDistance> _filterAndSort(List<PostModel> posts) {
    final results = <_PostWithDistance>[];

    for (final post in posts) {
      // Skip posts from blocked users.
      if (_blockedUsers.contains(post.userId)) continue;

      if (post.global) {
        // Global posts: show if toggle is on.
        if (_showGlobal) {
          double? dist;
          if (_userLocation != null && post.location != null) {
            dist = distanceKm(_userLocation!, post.location!);
          }
          results.add(_PostWithDistance(post, dist));
        }
        continue;
      }

      // Local posts: show if within the post's own radius from the user.
      if (_userLocation == null || post.location == null) continue;
      final dist = distanceKm(_userLocation!, post.location!);
      if (dist <= post.radius) {
        results.add(_PostWithDistance(post, dist));
      }
    }

    // Sort: closest first, then newest.
    results.sort((a, b) {
      if (a.distance != null && b.distance != null) {
        final cmp = a.distance!.compareTo(b.distance!);
        if (cmp != 0) return cmp;
      } else if (a.distance != null) {
        return -1;
      } else if (b.distance != null) {
        return 1;
      }
      return b.post.expiresAt.compareTo(a.post.expiresAt);
    });

    return results;
  }

  void _openFilterSheet() {
    final prefs = context.read<PreferencesService>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Feed filters',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show global posts'),
                    value: _showGlobal,
                    onChanged: (v) {
                      setSheetState(() => _showGlobal = v);
                      setState(() => _showGlobal = v);
                      prefs.showGlobalPosts = v;
                    },
                  ),
                  if (_userLocation == null)
                    const ListTile(
                      leading: Icon(Icons.location_off),
                      title: Text('Location unavailable'),
                      subtitle: Text(
                          'Enable location to see nearby posts and distances.'),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                          'Show local posts within ${_localRadiusKm.toStringAsFixed(0)} km'),
                    ),
                    Slider(
                      value: _localRadiusKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${_localRadiusKm.toStringAsFixed(0)} km',
                      onChanged: (v) {
                        setSheetState(() => _localRadiusKm = v);
                        setState(() => _localRadiusKm = v);
                        prefs.localRadiusKm = v;
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: _locationLoading
          ? const LoadingView(message: 'Getting your location...')
          : StreamBuilder(
              stream: firestore.getActivePosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading posts...');
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message:
                        'Could not load posts. Check your connection and try again.',
                    onRetry: () => (context as Element).markNeedsBuild(),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                final allPosts =
                    docs.map((d) => PostModel.fromFirestore(d)).toList();
                final filtered = _filterAndSort(allPosts);

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.post_add,
                    title: 'No nearby posts',
                    subtitle:
                        'No active posts match your filters. Try adjusting your radius or enabling global posts.',
                  );
                }

                final uid = FirebaseAuth.instance.currentUser?.uid;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    return PostCard(
                      post: item.post,
                      distanceKm: item.distance,
                      isOwn: item.post.userId == uid,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PostDetailScreen(postId: item.post.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PostWithDistance {
  final PostModel post;
  final double? distance;
  const _PostWithDistance(this.post, this.distance);
}
