import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../provider/emergency_sos_provider.dart';

/// Page to Add a New Emergency Contact to Firestore
class AddEmergencyContactPage extends StatefulWidget {
  const AddEmergencyContactPage({super.key});

  @override
  State<AddEmergencyContactPage> createState() => _AddEmergencyContactPageState();
}

class _AddEmergencyContactPageState extends State<AddEmergencyContactPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedRelationship = 'family';
  bool _isPrimary = false;

  final Map<String, String> _relationships = {
    'family': 'Family Member',
    'friend': 'Friend',
    'caregiver': 'Caregiver / Assistant',
    'emergency_services': 'Emergency Services',
    'other': 'Other',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sosProvider = Provider.of<EmergencySosProvider>(context, listen: false);
    final userId = authProvider.user?.userId ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to add emergency contacts.')),
      );
      return;
    }

    final contact = EmergencyContactEntity(
      contactId: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _selectedRelationship,
      isPrimary: _isPrimary,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      createdAt: DateTime.now(),
    );

    await sosProvider.addContact(contact);

    if (context.mounted) {
      AccessibilityScaffold.announce('Emergency contact ${contact.name} added successfully.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sosProvider = Provider.of<EmergencySosProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Add Emergency Contact',
      appBar: const CustomAppBar(title: 'Add Contact'),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              AdiuvaSpacing.gapMd,

              // Name Field
              CustomTextField(
                label: 'Full Name',
                hintText: 'e.g. Jane Doe',
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter contact name';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapMd,

              // Phone Field
              CustomTextField(
                label: 'Phone Number',
                hintText: 'e.g. +1234567890',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapMd,

              // Relationship Dropdown
              Text('Relationship', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _relationships.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRelationship = val;
                    });
                  }
                },
              ),
              AdiuvaSpacing.gapLg,

              // Primary Switch
              AdiuvaCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  title: Text('Primary Emergency Contact', style: theme.textTheme.titleMedium),
                  subtitle: const Text('Designate as first priority for SOS alerts'),
                  value: _isPrimary,
                  onChanged: (val) {
                    setState(() {
                      _isPrimary = val;
                    });
                  },
                ),
              ),
              AdiuvaSpacing.gapXxl,

              // Save Button
              CustomButton.primary(
                label: 'Save Emergency Contact',
                isLoading: sosProvider.isLoading,
                leadingIcon: Icons.check_circle_outline_rounded,
                onPressed: () => _submit(context),
              ),
              AdiuvaSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}
