import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../provider/auth_provider.dart';

/// Screen asking new / unconfigured users: "What should I call you?"
class NicknamePromptPage extends StatefulWidget {
  const NicknamePromptPage({super.key});

  @override
  State<NicknamePromptPage> createState() => _NicknamePromptPageState();
}

class _NicknamePromptPageState extends State<NicknamePromptPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitPreferredName() async {
    final nameText = _nameController.text.trim();
    if (nameText.isEmpty) {
      _skipToHome();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updatePreferredName(nameText);

    if (!mounted) return;
    debugPrint('[AUTH_FINAL] route=${AppRoutes.home}');
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _skipToHome() async {
    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final fullName = (user != null && user.name.trim().isNotEmpty) ? user.name.trim() : 'User';

    // Save preferredName using user's existing full name so returning user checks will never ask again
    await authProvider.updatePreferredName(fullName);

    if (!mounted) return;
    debugPrint('[AUTH_FINAL] route=${AppRoutes.home}');
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AccessibilityScaffold(
      pageTitle: 'Set Preferred Name',
      initialAnnouncement: 'What should I call you? Enter your preferred nickname.',
      body: Center(
        child: SingleChildScrollView(
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AdiuvaColors.primaryTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  size: 48,
                  color: AdiuvaColors.primaryTeal,
                ),
              ),
              AdiuvaSpacing.gapLg,
              Text(
                'What should I call you?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'ADIUVA uses your preferred name for natural voice greetings and assistance.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapXl,

              // Preferred Name Input Field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Preferred Name / Nickname',
                  hintText: 'e.g. Keerth, Kiki, Keeru',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onFieldSubmitted: (_) => _submitPreferredName(),
              ),
              AdiuvaSpacing.gapLg,

              // Save & Continue Button
              CustomButton(
                label: 'Continue',
                onPressed: _isSaving ? null : _submitPreferredName,
                isLoading: _isSaving,
              ),
              AdiuvaSpacing.gapMd,

              // Skip Button
              CustomButton.outlined(
                label: 'Skip for now',
                onPressed: _isSaving ? null : _skipToHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
