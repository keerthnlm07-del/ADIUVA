import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../domain/entities/isl_avatar_character.dart';

/// Modal Bottom Sheet allowing the user to choose their preferred 3D ISL Avatar
class CharacterSelectorSheet extends StatelessWidget {
  final IslAvatarCharacter currentSelection;
  final ValueChanged<IslAvatarCharacter> onCharacterSelected;

  const CharacterSelectorSheet({
    super.key,
    required this.currentSelection,
    required this.onCharacterSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required IslAvatarCharacter currentSelection,
    required ValueChanged<IslAvatarCharacter> onCharacterSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CharacterSelectorSheet(
        currentSelection: currentSelection,
        onCharacterSelected: (char) {
          Navigator.of(ctx).pop();
          onCharacterSelected(char);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Select Indian Sign Language Avatar Character',
      child: Container(
        padding: const EdgeInsets.all(AdiuvaSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AdiuvaSpacing.gapMd,

            // Header title
            Row(
              children: [
                const Icon(
                  Icons.switch_account_rounded,
                  color: AdiuvaColors.primaryTeal,
                  size: 26,
                ),
                AdiuvaSpacing.gapSm,
                Text(
                  'Choose ISL Avatar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AdiuvaSpacing.gapXs,
            Text(
              'Select the 3D humanoid character to present Indian Sign Language animations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AdiuvaSpacing.gapLg,

            // Character Options List
            ...IslAvatarCharacter.all.map((character) {
              final isSelected = character.id == currentSelection.id;
              final isMale = character.id == 'male';

              return Padding(
                padding: const EdgeInsets.only(bottom: AdiuvaSpacing.md),
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  label: '${character.name}, ${character.description}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onCharacterSelected(character),
                    child: Container(
                      padding: const EdgeInsets.all(AdiuvaSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AdiuvaColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1)
                            : (isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AdiuvaColors.primaryTeal
                              : (isDark ? AdiuvaColors.darkBorder : AdiuvaColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Character Avatar Icon Badge
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AdiuvaColors.primaryTeal
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMale ? Icons.face_rounded : Icons.face_3_rounded,
                              size: 28,
                              color: isSelected ? Colors.white : AdiuvaColors.primaryTeal,
                            ),
                          ),
                          AdiuvaSpacing.gapMd,

                          // Character Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      character.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AdiuvaColors.primaryTeal
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      AdiuvaSpacing.gapXs,
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AdiuvaColors.primaryTeal,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  character.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Radio Selection Indicator
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AdiuvaColors.primaryTeal : theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            AdiuvaSpacing.gapSm,
            // Dismiss button
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
            AdiuvaSpacing.gapMd,
          ],
        ),
      ),
    );
  }
}
