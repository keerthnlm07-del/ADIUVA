import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/emergency_sos_provider.dart';
import '../widgets/emergency_contact_card.dart';

/// Page Displaying User's Emergency Contacts List from Cloud Firestore
class EmergencyContactsListPage extends StatefulWidget {
  const EmergencyContactsListPage({super.key});

  @override
  State<EmergencyContactsListPage> createState() => _EmergencyContactsListPageState();
}

class _EmergencyContactsListPageState extends State<EmergencyContactsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sosProvider = Provider.of<EmergencySosProvider>(context, listen: false);
      final userId = authProvider.user?.userId ?? '';
      if (userId.isNotEmpty) {
        sosProvider.fetchContacts(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<EmergencySosProvider>(context);
    final contacts = sosProvider.contacts;

    return AccessibilityScaffold(
      pageTitle: 'Emergency Contacts',
      appBar: const CustomAppBar(title: 'Emergency Contacts'),
      body: Column(
        children: [
          Expanded(
            child: sosProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AdiuvaColors.primaryTeal),
                    ),
                  )
                : contacts.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: AdiuvaSpacing.paddingLg,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return EmergencyContactCard(
                            contact: contact,
                            onDelete: () async {
                              await sosProvider.deleteContact(contact.contactId);
                              if (context.mounted) {
                                AccessibilityScaffold.announce(
                                  'Deleted contact ${contact.name}',
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
          Padding(
            padding: AdiuvaSpacing.paddingLg,
            child: CustomButton.primary(
              label: 'Add Emergency Contact',
              leadingIcon: Icons.add_circle_outline_rounded,
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.addEmergencyContact);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AdiuvaSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AdiuvaColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts_outlined,
                size: 40,
                color: AdiuvaColors.primaryTeal,
              ),
            ),
            AdiuvaSpacing.gapLg,
            Text(
              'No Emergency Contacts Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapSm,
            Text(
              'Add family members or trusted contacts to receive automatic location alerts during emergency SOS calls.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
