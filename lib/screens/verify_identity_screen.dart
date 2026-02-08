import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/storage_service.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  bool _submitting = false;
  bool _alreadyRequested = false;
  bool _loading = true;

  XFile? _idPhoto;
  XFile? _selfiePhoto;

  // QR code session state
  String? _qrSessionId;
  StreamSubscription<DocumentSnapshot>? _qrPollSub;
  Duration _qrTimeRemaining = Duration.zero;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _qrPollSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final existing = await FirebaseFirestore.instance
        .collection('verification_requests')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        _alreadyRequested = existing.docs.isNotEmpty;
        _loading = false;
      });
    }
  }

  Future<void> _pickIdPhoto() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Photo of your ID'),
        content: const Text(
            'Take a clear photo of your government-issued ID.'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _idPhoto = picked);
    }
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked != null && mounted) {
        setState(() => _selfiePhoto = picked);
      }
    } catch (e) {
      // Camera not available — offer QR code fallback
      if (mounted) {
        final useQr = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera unavailable'),
            content: const Text(
              'Your device doesn\'t seem to have a camera available. '
              'You can scan a QR code with your phone to take the selfie there instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.qr_code),
                label: const Text('Show QR code'),
              ),
            ],
          ),
        );
        if (useQr == true && mounted) {
          _startQrSession();
        }
      }
    }
  }

  Future<void> _startQrSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Create a Firestore session document with a 1-hour expiry
    final expiresAt = DateTime.now().add(const Duration(hours: 1));
    final docRef =
        await FirebaseFirestore.instance.collection('selfie_sessions').add({
      'userId': uid,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'selfieUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _qrSessionId = docRef.id;
      _qrTimeRemaining = const Duration(hours: 1);
    });

    // Start countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _cancelQrSession(expired: true);
      } else {
        setState(() => _qrTimeRemaining = remaining);
      }
    });

    // Poll for selfie upload
    _qrPollSub?.cancel();
    _qrPollSub = FirebaseFirestore.instance
        .collection('selfie_sessions')
        .doc(docRef.id)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data == null) return;
      final selfieUrl = data['selfieUrl'] as String?;
      if (selfieUrl != null && selfieUrl.isNotEmpty) {
        // Selfie uploaded via QR flow — store the URL and clear QR state
        _qrPollSub?.cancel();
        _countdownTimer?.cancel();
        setState(() {
          // We'll store the URL in a special way — create a fake XFile isn't ideal,
          // so we store the URL directly and handle it in _submitRequest.
          _qrSelfieUrl = selfieUrl;
          _qrSessionId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selfie received from your phone!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    });
  }

  String? _qrSelfieUrl;

  void _cancelQrSession({bool expired = false}) {
    _qrPollSub?.cancel();
    _countdownTimer?.cancel();
    if (_qrSessionId != null) {
      // Delete the session doc
      FirebaseFirestore.instance
          .collection('selfie_sessions')
          .doc(_qrSessionId)
          .delete();
    }
    if (mounted) {
      setState(() {
        _qrSessionId = null;
        _qrTimeRemaining = Duration.zero;
      });
      if (expired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR session expired. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    }
  }

  bool get _hasSelfie => _selfiePhoto != null || _qrSelfieUrl != null;

  Future<void> _submitRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_idPhoto == null || !_hasSelfie) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide both your ID photo and selfie.'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final storage = context.read<StorageService>();

      final idBytes = await _idPhoto!.readAsBytes();
      final idUrl = await storage.uploadVerificationImage(
        userId: uid,
        imageType: 'id',
        bytes: idBytes,
      );

      String selfieUrl;
      if (_qrSelfieUrl != null) {
        // Selfie was uploaded via QR flow — URL already in Storage
        selfieUrl = _qrSelfieUrl!;
      } else {
        final selfieBytes = await _selfiePhoto!.readAsBytes();
        selfieUrl = await storage.uploadVerificationImage(
          userId: uid,
          imageType: 'selfie',
          bytes: selfieBytes,
        );
      }

      await FirebaseFirestore.instance
          .collection('verification_requests')
          .add({
        'userId': uid,
        'status': 'pending',
        'idPhotoUrl': idUrl,
        'selfiePhotoUrl': selfieUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _alreadyRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Verification request submitted! We\'ll review it soon.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit request. Try again later.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify identity')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Get Verified',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A verified badge shows neighbors that your identity '
                          'has been confirmed by MicroHelp.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Steps
                  Text(
                    'How it works',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _StepTile(
                    number: '1',
                    title: 'Upload your government ID',
                    subtitle:
                        'Take a clear photo of your government-issued photo ID '
                        '(passport, driver\'s license, etc.).',
                  ),
                  const _StepTile(
                    number: '2',
                    title: 'Take a live selfie with your ID',
                    subtitle:
                        'Use your camera to take a real-time photo of yourself '
                        'holding your ID. No gallery uploads allowed for security. '
                        'If your device has no camera, scan a QR code to use your phone.',
                  ),
                  const _StepTile(
                    number: '3',
                    title: 'Admin review',
                    subtitle:
                        'Our team reviews your photos. Images are deleted after verification.',
                  ),
                  const _StepTile(
                    number: '4',
                    title: 'Get your badge',
                    subtitle:
                        'Once approved, a verified badge appears on your profile.',
                  ),
                  const SizedBox(height: 24),

                  if (_alreadyRequested)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top,
                              color: theme.colorScheme.onSecondaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your verification request is pending review. '
                              'We\'ll update your profile once approved.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // ID photo upload (camera or gallery)
                    _PhotoUploadCard(
                      title: 'Government ID',
                      subtitle: 'Photo of your government-issued ID',
                      icon: Icons.badge_outlined,
                      hasPhoto: _idPhoto != null,
                      onTap: _submitting ? null : _pickIdPhoto,
                    ),
                    const SizedBox(height: 12),

                    // Selfie capture (camera only) or QR code flow
                    if (_qrSessionId != null)
                      _QrSessionCard(
                        sessionId: _qrSessionId!,
                        timeRemaining: _qrTimeRemaining,
                        onCancel: () => _cancelQrSession(),
                      )
                    else
                      _PhotoUploadCard(
                        title: 'Live selfie with ID',
                        subtitle: _hasSelfie
                            ? 'Selfie captured — tap to retake'
                            : 'Take a real-time photo holding your ID',
                        icon: Icons.face,
                        hasPhoto: _hasSelfie,
                        onTap: _submitting ? null : _takeSelfie,
                        cameraOnly: true,
                      ),

                    if (!_hasSelfie && _qrSessionId == null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _submitting ? null : _startQrSession,
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('No camera? Use QR code instead'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submitRequest,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user),
                      label: Text(_submitting
                          ? 'Uploading...'
                          : 'Submit verification'),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Your photos are securely stored and will be deleted '
                      'after verification is complete.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Card showing the QR code for the mobile selfie upload session.
class _QrSessionCard extends StatelessWidget {
  const _QrSessionCard({
    required this.sessionId,
    required this.timeRemaining,
    required this.onCancel,
  });

  final String sessionId;
  final Duration timeRemaining;
  final VoidCallback onCancel;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The QR code value is the session ID — the mobile upload page
    // will use this to find the Firestore document and upload the selfie.
    final qrData = 'microhelp://selfie-session/$sessionId';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Scan with your phone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open the camera app on your phone and scan this QR code to take your selfie there.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Expires in ${_formatDuration(timeRemaining)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: timeRemaining.inMinutes < 5
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CircularProgressIndicator(
              value: timeRemaining.inSeconds / 3600,
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for selfie...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoUploadCard extends StatelessWidget {
  const _PhotoUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hasPhoto,
    required this.onTap,
    this.cameraOnly = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool hasPhoto;
  final VoidCallback? onTap;
  final bool cameraOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasPhoto
                      ? theme.colorScheme.primary.withAlpha(26)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasPhoto ? Icons.check_circle : icon,
                  color: hasPhoto
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasPhoto ? 'Photo selected — tap to retake' : subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (cameraOnly && !hasPhoto)
                      Text(
                        'Camera only — no gallery uploads',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                cameraOnly ? Icons.camera_alt : Icons.camera_alt_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              number,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
