import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/preferences_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/first_time_tip_banner.dart';
import '../widgets/loading_view.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list_item.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.onNavigateToCreatePost});

  final VoidCallback? onNavigateToCreatePost;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  GeoPoint? _userLocation;
  bool _locationLoading = true;
  late bool _showGlobal;
  late double _localRadiusKm;
  Set<String> _blockedUsers = {};
  PostType? _typeFilter; // null = show all
  String? _userName;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<PreferencesService>();
    _showGlobal = prefs.showGlobalPosts;
    _localRadiusKm = prefs.localRadiusKm;
    _loadUserLocation();
    _loadBlockedUsers();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final firestore = context.read<FirestoreService>();
    try {
      final doc = await firestore.getUser(uid, source: Source.cache);
      if (mounted && doc.exists) {
        setState(() => _userName = doc.data()?['name'] as String?);
      }
    } catch (_) {
      try {
        final doc = await firestore.getUser(uid);
        if (mounted && doc.exists) {
          setState(() => _userName = doc.data()?['name'] as String?);
        }
      } catch (_) {}
    }
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
      if (!mounted) return;
      final loc = await getAndSaveUserLocation(context, showRationale: false);
      if (mounted) {
        setState(() {
          _userLocation = loc;
          _locationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadUserLocation(),
      _loadBlockedUsers(),
    ]);
  }

  List<_PostWithDistance> _filterAndSort(List<PostModel> posts) {
    final results = <_PostWithDistance>[];

    for (final post in posts) {
      // Skip posts from blocked users.
      if (_blockedUsers.contains(post.userId)) continue;

      // Type filter
      if (_typeFilter != null && post.type != _typeFilter) continue;

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
                          'Show local posts within ${_localRadiusKm < 1 ? '${(_localRadiusKm * 1000).toStringAsFixed(0)} m' : '${_localRadiusKm.toStringAsFixed(0)} km'}'),
                    ),
                    Slider(
                      value: _localRadiusKm,
                      min: 0.5,
                      max: 50,
                      divisions: 99,
                      label: _localRadiusKm < 1
                          ? '${(_localRadiusKm * 1000).toStringAsFixed(0)} m'
                          : '${_localRadiusKm.toStringAsFixed(0)} km',
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userName != null && _userName!.isNotEmpty)
              Text(
                '${_greeting()}, ${_userName!.split(' ').first}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              )
            else
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            Text(
              'See what\u2019s happening nearby',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
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
                  return const ShimmerLoadingList(
                    itemCount: 5,
                    type: ShimmerListType.postCard,
                  );
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

                // Count requests and offers (before type filter) for chip badges
                final preFilteredPosts = allPosts.where((p) =>
                    !_blockedUsers.contains(p.userId)).toList();
                final requestCount = preFilteredPosts
                    .where((p) => p.type == PostType.request)
                    .length;
                final offerCount = preFilteredPosts
                    .where((p) => p.type == PostType.offer)
                    .length;

                final filtered = _filterAndSort(allPosts);
                final prefs = context.read<PreferencesService>();
                final showFeedTip = !prefs.hasSeenFeedTip;

                return Column(
                  children: [
                    // Type filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            count: requestCount + offerCount,
                            selected: _typeFilter == null,
                            onTap: () =>
                                setState(() => _typeFilter = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Requests',
                            count: requestCount,
                            selected: _typeFilter == PostType.request,
                            color: cs.primary,
                            onTap: () => setState(() => _typeFilter =
                                _typeFilter == PostType.request
                                    ? null
                                    : PostType.request),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Offers',
                            count: offerCount,
                            selected: _typeFilter == PostType.offer,
                            color: cs.tertiary,
                            onTap: () => setState(() => _typeFilter =
                                _typeFilter == PostType.offer
                                    ? null
                                    : PostType.offer),
                          ),
                        ],
                      ),
                    ),
                    if (showFeedTip)
                      FirstTimeTipBanner(
                        message:
                            'Tap a post to view details and accept. Your own posts show as "Yours" on the feed.',
                        onDismiss: () {
                          prefs.hasSeenFeedTip = true;
                          if (mounted) setState(() {});
                        },
                      ),
                    Expanded(
                      child: filtered.isEmpty
                          ? EmptyStateView(
                              icon: Icons.explore_outlined,
                              title: 'Nothing here yet',
                              subtitle:
                                  'No active posts match your filters. Try adjusting your radius or enabling global posts.',
                              primaryActionLabel: 'Adjust filters',
                              onPrimaryAction: _openFilterSheet,
                              secondaryActionLabel:
                                  widget.onNavigateToCreatePost != null
                                      ? 'Create a post'
                                      : null,
                              onSecondaryAction:
                                  widget.onNavigateToCreatePost,
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                    top: 4, bottom: 80),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final item = filtered[i];
                                  final uid = FirebaseAuth
                                      .instance.currentUser?.uid;
                                  return StaggeredListItem(
                                    index: i,
                                    child: PostCard(
                                      post: item.post,
                                      distanceKm: item.distance,
                                      isOwn: item.post.userId == uid,
                                      onTap: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PostDetailScreen(
                                                  postId:
                                                      item.post.id),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withAlpha(30)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? effectiveColor.withAlpha(120)
                : cs.outline.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? effectiveColor : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? effectiveColor.withAlpha(40)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? effectiveColor : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostWithDistance {
  final PostModel post;
  final double? distance;
  const _PostWithDistance(this.post, this.distance);
}
