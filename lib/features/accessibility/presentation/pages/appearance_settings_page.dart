import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/accessibility_provider.dart';

/// ADIUVA Appearance Settings Page
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AccessibilityProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Appearance Settings',
      appBar: const CustomAppBar(title: 'Appearance Settings'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme & Color Display Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System Default'),
                    subtitle: const Text('Follow system brightness settings'),
                    value: ThemeMode.system,
                    // ignore: deprecated_member_use
                    groupValue: provider.themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) provider.setThemeMode(val);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Mode'),
                    subtitle: const Text('Verdant Teal and light surface styling'),
                    value: ThemeMode.light,
                    // ignore: deprecated_member_use
                    groupValue: provider.themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) provider.setThemeMode(val);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Dark Slate background with high legibility'),
                    value: ThemeMode.dark,
                    // ignore: deprecated_member_use
                    groupValue: provider.themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) provider.setThemeMode(val);
                    },
                  ),
                ],
              ),
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
