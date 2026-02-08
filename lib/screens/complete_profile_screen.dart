import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../widgets/location_autocomplete_field.dart';
import 'home_screen.dart';

const _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say', 'Other'];

/// Shown after social sign-up (Google / Apple) so the user fills in
/// the community fields that the social provider doesn't supply.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.prefillName,
  });

  final String uid;
  final String? prefillName;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _neighborhoodCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _genderOtherCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();

  bool _saving = false;
  DateTime? _birthday;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _bioCtrl.dispose();
    _genderOtherCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Almost there!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell us a bit about yourself so we can connect you with your community.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Display name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                // Birthday
                GestureDetector(
                  onTap: _pickBirthday,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _birthdayCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Birthday',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                        hintText: 'Tap to select',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (_) {
                        if (_birthday == null) return 'Select your birthday';
                        if (_calculateAge(_birthday!) < 18) {
                          return 'You must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people_outlined),
                  ),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select your gender' : null,
                ),

                if (_gender == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _genderOtherCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Please specify',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (v) {
                      if (_gender == 'Other' &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Please specify your gender';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Neighborhood
                LocationAutocompleteField(
                  controller: _neighborhoodCtrl,
                  helperText: 'Helps connect you with nearby neighbors',
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Short bio (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outlined),
                    hintText: 'Tell your neighbors a bit about yourself...',
                    alignLabelWithHint: true,
                  ),
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
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birthday',
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayCtrl.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final effectiveGender =
          _gender == 'Other' ? _genderOtherCtrl.text.trim() : _gender;

      final auth = context.read<AuthService>();
      await auth.updateUserProfile(
        widget.uid,
        name: _nameCtrl.text.trim(),
        birthday: _birthday!,
        gender: effectiveGender!,
        neighborhood: _neighborhoodCtrl.text.trim().isNotEmpty
            ? _neighborhoodCtrl.text.trim()
            : null,
        bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      );

      if (!mounted) return;
      final analytics = context.read<AnalyticsService>();
      analytics.setUserProperties(userId: widget.uid);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (r) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save. Check your connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
