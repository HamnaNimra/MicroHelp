import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

const _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say', 'Other'];
const _ageRangeOptions = ['18-25', '26-35', '36-45', '46-60', '60+'];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _neighborhoodCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _genderOtherCtrl;
  final _formKey = GlobalKey<FormState>();
  String? _gender;
  String? _ageRange;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _neighborhoodCtrl = TextEditingController(text: widget.user.neighborhood);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _ageRange = widget.user.ageRange;

    // If the stored gender is not in the standard options, treat it as "Other"
    if (widget.user.gender != null &&
        !_genderOptions.contains(widget.user.gender)) {
      _gender = 'Other';
      _genderOtherCtrl = TextEditingController(text: widget.user.gender);
    } else {
      _gender = widget.user.gender;
      _genderOtherCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _neighborhoodCtrl.dispose();
    _bioCtrl.dispose();
    _genderOtherCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final effectiveGender =
          _gender == 'Other' ? _genderOtherCtrl.text.trim() : _gender;

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'lastActive': FieldValue.serverTimestamp(),
      };
      if (effectiveGender != null) updates['gender'] = effectiveGender;
      if (_ageRange != null) updates['ageRange'] = _ageRange;
      if (_neighborhoodCtrl.text.trim().isNotEmpty) {
        updates['neighborhood'] = _neighborhoodCtrl.text.trim();
      }
      if (_bioCtrl.text.trim().isNotEmpty) {
        updates['bio'] = _bioCtrl.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(updates);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Check your connection and try again.'),
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
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
              if (_gender == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genderOtherCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
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
              DropdownButtonFormField<String>(
                initialValue: _ageRange,
                decoration: const InputDecoration(
                  labelText: 'Age range',
                  border: OutlineInputBorder(),
                ),
                items: _ageRangeOptions
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _ageRange = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _neighborhoodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Neighborhood or postal code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Short bio',
                  border: OutlineInputBorder(),
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
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
