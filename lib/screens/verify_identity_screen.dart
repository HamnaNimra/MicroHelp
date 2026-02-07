import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  bool _submitting = false;
  bool _alreadyRequested = false;
  bool _loading = true;

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

  Future<void> _submitRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('verification_requests')
          .add({
        'userId': uid,
        'status': 'pending',
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
                    title: 'Submit a request',
                    subtitle: 'Tap the button below to start the process.',
                  ),
                  const _StepTile(
                    number: '2',
                    title: 'Admin review',
                    subtitle:
                        'Our team will review your account and may contact you for ID confirmation.',
                  ),
                  const _StepTile(
                    number: '3',
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
                  else
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submitRequest,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user),
                      label: const Text('Request verification'),
                    ),
                ],
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
