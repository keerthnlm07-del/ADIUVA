import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/accessibility_provider.dart';

/// ADIUVA Language & Speech Recognition Locale Settings Page
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  static const Map<String, String> _supportedAppLanguages = {
    'en': 'English (United States)',
    'es': 'Español (Spanish)',
    'hi': 'हिन्दी (Hindi)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
  };

  static const Map<String, String> _supportedSpeechLocales = {
    'en-US': 'English (United States) [en-US]',
    'es-ES': 'Spanish (Spain) [es-ES]',
    'hi-IN': 'Hindi (India) [hi-IN]',
    'fr-FR': 'French (France) [fr-FR]',
    'de-DE': 'German (Germany) [de-DE]',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AccessibilityProvider>(context);

    return AccessibilityScaffold(
      pageTitle: 'Language & Locale Settings',
      appBar: const CustomAppBar(title: 'Language Settings'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Display Language',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _supportedAppLanguages.entries.map((entry) {
                  return RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(entry.value, style: theme.textTheme.titleMedium),
                    value: entry.key,
                    // ignore: deprecated_member_use
                    groupValue: provider.appLanguage,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        provider.setAppLanguage(val);
                        AccessibilityScaffold.announce('App language set to ${entry.value}');
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            AdiuvaSpacing.gapXl,

            Text(
              'Speech Recognition Locale',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapMd,
            AdiuvaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _supportedSpeechLocales.entries.map((entry) {
                  return RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(entry.value, style: theme.textTheme.titleMedium),
                    value: entry.key,
                    // ignore: deprecated_member_use
                    groupValue: provider.speechLocale,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        provider.setSpeechLocale(val);
                        AccessibilityScaffold.announce('Speech locale set to ${entry.value}');
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            AdiuvaSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
