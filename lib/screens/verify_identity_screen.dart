import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
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

  Future<void> _pickImage({required bool isSelfie}) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSelfie ? 'Take a selfie' : 'Photo of your ID'),
        content: Text(isSelfie
            ? 'Take a clear photo of yourself holding your ID.'
            : 'Take a clear photo of your government-issued ID.'),
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
    if (picked == null) return;

    setState(() {
      if (isSelfie) {
        _selfiePhoto = picked;
      } else {
        _idPhoto = picked;
      }
    });
  }

  Future<void> _submitRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_idPhoto == null || _selfiePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both your ID photo and selfie.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final storage = context.read<StorageService>();

      final idBytes = await _idPhoto!.readAsBytes();
      final selfieBytes = await _selfiePhoto!.readAsBytes();

      final idUrl = await storage.uploadVerificationImage(
        userId: uid,
        imageType: 'id',
        bytes: idBytes,
      );
      final selfieUrl = await storage.uploadVerificationImage(
        userId: uid,
        imageType: 'selfie',
        bytes: selfieBytes,
      );

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
          const SnackBar(
            content: Text('Verification request submitted! We\'ll review it soon.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit request. Try again later.'),
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
                    title: 'Take a selfie with your ID',
                    subtitle:
                        'Take a photo of yourself holding your ID next to your face.',
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
                    // ID photo upload
                    _PhotoUploadCard(
                      title: 'Government ID',
                      subtitle: 'Photo of your government-issued ID',
                      icon: Icons.badge_outlined,
                      hasPhoto: _idPhoto != null,
                      onTap: _submitting
                          ? null
                          : () => _pickImage(isSelfie: false),
                    ),
                    const SizedBox(height: 12),

                    // Selfie upload
                    _PhotoUploadCard(
                      title: 'Selfie with ID',
                      subtitle: 'Photo of you holding your ID',
                      icon: Icons.face,
                      hasPhoto: _selfiePhoto != null,
                      onTap: _submitting
                          ? null
                          : () => _pickImage(isSelfie: true),
                    ),
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

class _PhotoUploadCard extends StatelessWidget {
  const _PhotoUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hasPhoto,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool hasPhoto;
  final VoidCallback? onTap;

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
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasPhoto ? Icons.check_circle : icon,
                  color: hasPhoto ? Colors.green : theme.colorScheme.onSurfaceVariant,
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
                  ],
                ),
              ),
              Icon(
                Icons.camera_alt_outlined,
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
