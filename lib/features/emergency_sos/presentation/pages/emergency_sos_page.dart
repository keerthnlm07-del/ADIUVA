import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/emergency_sos_provider.dart';

/// Full ADIUVA Emergency SOS Activation & Confirmation Screen
class EmergencySosPage extends StatelessWidget {
  const EmergencySosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<EmergencySosProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.userId ?? '';
    final state = sosProvider.state;

    return AccessibilityScaffold(
      pageTitle: 'Emergency SOS',
      appBar: CustomAppBar(
        title: 'Emergency SOS',
        showBackButton: true,
        onBackPressed: () {
          if (state == SosStateEnum.sending) return;
          sosProvider.resolveSos();
          Navigator.of(context).pop();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AdiuvaSpacing.gapLg,

            // SOS Status Icon & Badge
            _buildStatusBadge(context, state),
            AdiuvaSpacing.gapXl,

            // Dynamic Body Content per State
            if (state == SosStateEnum.idle) ...[
              _buildIdleContent(context, sosProvider),
            ] else if (state == SosStateEnum.confirmation) ...[
              _buildConfirmationContent(context, sosProvider, userId),
            ] else if (state == SosStateEnum.sending) ...[
              _buildSendingContent(context),
            ] else if (state == SosStateEnum.success) ...[
              _buildSuccessContent(context, sosProvider),
            ] else if (state == SosStateEnum.failure) ...[
              _buildFailureContent(context, sosProvider, userId),
            ] else if (state == SosStateEnum.cancelled) ...[
              _buildCancelledContent(context),
            ],
            AdiuvaSpacing.gapXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SosStateEnum state) {
    final theme = Theme.of(context);

    Color bg;
    IconData icon;
    String text;

    switch (state) {
      case SosStateEnum.idle:
        bg = AdiuvaColors.error;
        icon = Icons.sos_rounded;
        text = 'EMERGENCY SOS READY';
        break;
      case SosStateEnum.confirmation:
        bg = AdiuvaColors.voiceAmberDark;
        icon = Icons.warning_amber_rounded;
        text = 'CONFIRMATION REQUIRED';
        break;
      case SosStateEnum.sending:
        bg = AdiuvaColors.primaryTeal;
        icon = Icons.sync_rounded;
        text = 'SENDING SOS ALERT...';
        break;
      case SosStateEnum.success:
        bg = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        text = 'EMERGENCY ALERT SENT';
        break;
      case SosStateEnum.failure:
        bg = AdiuvaColors.error;
        icon = Icons.error_rounded;
        text = 'SOS TRANSMISSION FAILED';
        break;
      case SosStateEnum.cancelled:
        bg = AdiuvaColors.slate500;
        icon = Icons.cancel_outlined;
        text = 'ALERT CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleContent(BuildContext context, EmergencySosProvider provider) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AdiuvaCard(
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            children: [
              const Icon(Icons.security, color: AdiuvaColors.error, size: 48),
              AdiuvaSpacing.gapMd,
              Text(
                'Emergency Assistance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AdiuvaColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Triggering SOS requires explicit confirmation. When confirmed, an emergency document will be saved to Cloud Firestore and your primary emergency contacts will be notified.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        AdiuvaSpacing.gapXxl,

        // 72dp High Contrast Trigger Button
        CustomButton.primary(
          label: 'TRIGGER EMERGENCY SOS',
          leadingIcon: Icons.warning_amber_rounded,
          onPressed: () {
            provider.requestSosConfirmation();
            AccessibilityScaffold.announce('SOS confirmation requested. Please confirm or cancel.');
          },
        ),
      ],
    );
  }

  Widget _buildConfirmationContent(
    BuildContext context,
    EmergencySosProvider provider,
    String userId,
  ) {
    final theme = Theme.of(context);

    return AdiuvaCard(
      padding: AdiuvaSpacing.paddingLg,
      backgroundColor: theme.colorScheme.errorContainer,
      child: Column(
        children: [
          Text(
            'Confirm Emergency Assistance',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          AdiuvaSpacing.gapMd,
          Text(
            'Are you sure you want to send an immediate emergency SOS alert? This action cannot be undone automatically.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          AdiuvaSpacing.gapXl,
          Row(
            children: [
              Expanded(
                child: CustomButton.outlined(
                  label: 'Cancel',
                  onPressed: () {
                    provider.cancelSos();
                    AccessibilityScaffold.announce('Emergency SOS alert cancelled.');
                  },
                ),
              ),
              const SizedBox(width: AdiuvaSpacing.md),
              Expanded(
                child: CustomButton.primary(
                  label: 'Confirm SOS',
                  leadingIcon: Icons.phone_in_talk_rounded,
                  onPressed: () {
                    provider.confirmAndSendSos(userId);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendingContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(AdiuvaColors.primaryTeal),
          ),
        ),
        AdiuvaSpacing.gapLg,
        Text(
          'Transmitting SOS Alert to Cloud Firestore...',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context, EmergencySosProvider provider) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AdiuvaCard(
          padding: AdiuvaSpacing.paddingLg,
          backgroundColor: Colors.green.shade50,
          child: Column(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 56),
              AdiuvaSpacing.gapMd,
              Text(
                'SOS Alert Transmitted Successfully',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Your emergency event has been logged to Cloud Firestore and your designated contacts have been notified.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        AdiuvaSpacing.gapXl,

        CustomButton.primary(
          label: 'Resolve Emergency',
          leadingIcon: Icons.check_rounded,
          onPressed: () {
            provider.resolveSos();
            AccessibilityScaffold.announce('Emergency event resolved.');
            Navigator.of(context).pop();
          },
        ),
        AdiuvaSpacing.gapMd,
        CustomButton.outlined(
          label: 'Cancel Alert Record',
          onPressed: () {
            provider.cancelSos();
          },
        ),
      ],
    );
  }

  Widget _buildFailureContent(
    BuildContext context,
    EmergencySosProvider provider,
    String userId,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AdiuvaCard(
          padding: AdiuvaSpacing.paddingLg,
          backgroundColor: theme.colorScheme.errorContainer,
          child: Text(
            provider.errorMessage ?? 'An error occurred while sending the emergency alert.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AdiuvaSpacing.gapXl,
        Row(
          children: [
            Expanded(
              child: CustomButton.outlined(
                label: 'Cancel',
                onPressed: () => provider.cancelSos(),
              ),
            ),
            const SizedBox(width: AdiuvaSpacing.md),
            Expanded(
              child: CustomButton.primary(
                label: 'Retry SOS',
                leadingIcon: Icons.refresh_rounded,
                onPressed: () => provider.confirmAndSendSos(userId),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelledContent(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Emergency alert cancelled.',
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
