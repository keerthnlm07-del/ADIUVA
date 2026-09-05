import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../domain/entities/emergency_contact_entity.dart';

/// Accessible Card for Emergency Contacts
class EmergencyContactCard extends StatelessWidget {
  final EmergencyContactEntity contact;
  final VoidCallback onDelete;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    required this.onDelete,
  });

  String _formatRelationship(String rel) {
    switch (rel) {
      case 'family':
        return 'Family Member';
      case 'friend':
        return 'Friend';
      case 'caregiver':
        return 'Caregiver / Assistant';
      case 'emergency_services':
        return 'Emergency Services';
      default:
        return 'Other Contact';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
      child: AdiuvaCard(
        padding: AdiuvaSpacing.paddingLg,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: contact.isPrimary
                  ? AdiuvaColors.error
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                contact.isPrimary ? Icons.star_rounded : Icons.person_outline_rounded,
                color: contact.isPrimary ? Colors.white : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AdiuvaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        contact.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdiuvaColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PRIMARY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AdiuvaColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRelationship(contact.relationship),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Delete emergency contact ${contact.name}',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AdiuvaColors.error),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
