import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/emergency_sos_provider.dart';

/// Full ADIUVA Emergency SOS Activation & Settings Screen
class EmergencySosPage extends StatefulWidget {
  const EmergencySosPage({super.key});

  @override
  State<EmergencySosPage> createState() => _EmergencySosPageState();
}

class _EmergencySosPageState extends State<EmergencySosPage> {
  final TextEditingController _codeWordController = TextEditingController();

  @override
  void dispose() {
    _codeWordController.dispose();
    super.dispose();
  }

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
          if (state == SosStateEnum.triggering) return;
          sosProvider.resolveSos();
          Navigator.of(context).pop();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AdiuvaSpacing.gapLg,

            // SOS Status Icon & Badge
            _buildStatusBadge(context, sosProvider),
            AdiuvaSpacing.gapXl,

            // Dynamic Body Content per State
            if (state == SosStateEnum.idle) ...[
              _buildIdleContent(context, sosProvider),
            ] else if (state == SosStateEnum.countdown) ...[
              _buildCountdownContent(context, sosProvider),
            ] else if (state == SosStateEnum.confirmingDanger) ...[
              _buildDangerConfirmationContent(context, sosProvider),
            ] else if (state == SosStateEnum.waitingForCodeWord) ...[
              _buildCodeWordPromptContent(context, sosProvider, userId),
            ] else if (state == SosStateEnum.triggering) ...[
              _buildSendingContent(context),
            ] else if (state == SosStateEnum.success || state == SosStateEnum.active) ...[
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

  Widget _buildStatusBadge(BuildContext context, EmergencySosProvider provider) {
    final theme = Theme.of(context);
    final state = provider.state;

    Color bg;
    IconData icon;
    String text;

    switch (state) {
      case SosStateEnum.idle:
        bg = AdiuvaColors.error;
        icon = Icons.sos_rounded;
        text = 'EMERGENCY SOS READY';
        break;
      case SosStateEnum.countdown:
        bg = AdiuvaColors.error;
        icon = Icons.timer_rounded;
        text = 'COUNTDOWN: ${provider.countdownSeconds}s';
        break;
      case SosStateEnum.confirmingDanger:
        bg = AdiuvaColors.voiceAmberDark;
        icon = Icons.warning_amber_rounded;
        text = 'ARE YOU IN DANGER?';
        break;
      case SosStateEnum.waitingForCodeWord:
        bg = Colors.deepOrange;
        icon = Icons.lock_clock_rounded;
        text = 'ENTER EMERGENCY CODE WORD';
        break;
      case SosStateEnum.triggering:
        bg = AdiuvaColors.primaryTeal;
        icon = Icons.sync_rounded;
        text = 'SENDING SOS ALERT...';
        break;
      case SosStateEnum.success:
      case SosStateEnum.active:
        bg = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        text = 'EMERGENCY ALERT ACTIVE';
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

  Widget _buildCountdownContent(BuildContext context, EmergencySosProvider provider) {
    final theme = Theme.of(context);
    final seconds = provider.countdownSeconds;
    final progress = seconds / 20.0;

    return AdiuvaCard(
      padding: AdiuvaSpacing.paddingXl,
      backgroundColor: Colors.red.shade50,
      borderSide: const BorderSide(color: AdiuvaColors.error, width: 2.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AdiuvaColors.error, size: 32),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'EMERGENCY SOS COUNTDOWN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AdiuvaColors.error,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          AdiuvaSpacing.gapLg,

          // Circular countdown indicator with large numbers
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.red.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(AdiuvaColors.error),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$seconds',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AdiuvaColors.error,
                        ),
                      ),
                      Text(
                        'SECONDS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdiuvaColors.error,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AdiuvaSpacing.gapLg,

          Text(
            'Deliberate phone shake detected. An automatic SMS with your current GPS location and a phone call will be placed to your emergency contact when the timer finishes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade900,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          AdiuvaSpacing.gapXl,

          // High-visibility Cancel SOS Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdiuvaColors.slate800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.close_rounded, size: 28),
              label: const Text(
                'CANCEL SOS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              onPressed: () {
                provider.cancelSosCountdown();
              },
            ),
          ),
          AdiuvaSpacing.gapMd,

          // Optional Skip Timer button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AdiuvaColors.error,
                side: const BorderSide(color: AdiuvaColors.error, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 22),
              label: const Text(
                'SEND NOW (SKIP TIMER)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                provider.executeAutomaticEmergencyWorkflow();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleContent(BuildContext context, EmergencySosProvider provider) {
    final theme = Theme.of(context);
    final hasContact = provider.getEffectiveEmergencyPhone().isNotEmpty;
    final hasCodeWord = provider.emergencyCodeWord.trim().isNotEmpty;

    return Column(
      children: [
        AdiuvaCard(
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            children: [
              const Icon(Icons.security_rounded, color: AdiuvaColors.error, size: 48),
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
                'Triggering SOS notifies your emergency contact with your current GPS location and initiates a phone call. You can trigger SOS via Manual Button, Voice ("SOS"), or 4–5 Deliberate Shakes (with 20s countdown).',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        AdiuvaSpacing.gapLg,

        // Emergency Contact & Code Word Settings Card
        AdiuvaCard(
          padding: AdiuvaSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.contact_phone_rounded, color: AdiuvaColors.primaryTeal),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contact',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AdiuvaColors.primaryTeal),
                    onPressed: () => _showEditSettingsDialog(context, provider),
                    tooltip: 'Edit Emergency Contact',
                  ),
                ],
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  hasContact ? provider.contactName : 'No Emergency Contact Set',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  hasContact ? provider.contactPhone : 'Tap edit icon above to configure',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Shake Emergency Code Word'),
                subtitle: Text(
                  hasCodeWord ? 'Configured (${provider.emergencyCodeWord})' : 'Not configured (Optional safeguard)',
                  style: TextStyle(color: hasCodeWord ? Colors.green.shade700 : AdiuvaColors.slate500),
                ),
              ),
            ],
          ),
        ),
        AdiuvaSpacing.gapLg,

        // Quick Direct Emergency Actions Card
        if (hasContact) ...[
          Row(
            children: [
              Expanded(
                child: CustomButton.secondary(
                  label: 'Direct Call',
                  leadingIcon: Icons.phone_rounded,
                  onPressed: () => provider.callEmergencyContact(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton.secondary(
                  label: 'Direct SMS',
                  leadingIcon: Icons.sms_rounded,
                  onPressed: () => provider.sendSmsSos(),
                ),
              ),
            ],
          ),
          AdiuvaSpacing.gapSm,
          CustomButton.secondary(
            label: 'Open WhatsApp Chat',
            leadingIcon: Icons.chat_rounded,
            onPressed: () => provider.sendWhatsAppSos(),
          ),
          AdiuvaSpacing.gapLg,
        ],

        // 20-Second Countdown Trigger Button
        CustomButton.secondary(
          label: 'START 20s SOS COUNTDOWN',
          leadingIcon: Icons.timer_outlined,
          onPressed: () {
            provider.startCountdown(source: 'manual');
          },
        ),
        AdiuvaSpacing.gapMd,

        // Immediate Danger Confirmation Trigger Button
        CustomButton.primary(
          label: 'TRIGGER EMERGENCY SOS',
          leadingIcon: Icons.warning_amber_rounded,
          onPressed: () {
            provider.requestSosConfirmation();
          },
        ),
      ],
    );
  }

  Widget _buildDangerConfirmationContent(BuildContext context, EmergencySosProvider provider) {
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
            'Are you in danger? Confirming will trigger an immediate emergency alert with your location and initiate a phone call.',
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
                  label: 'No / Cancel',
                  onPressed: () {
                    provider.cancelSos();
                  },
                ),
              ),
              const SizedBox(width: AdiuvaSpacing.md),
              Expanded(
                child: CustomButton.primary(
                  label: 'Yes, Confirm',
                  leadingIcon: Icons.phone_in_talk_rounded,
                  onPressed: () {
                    provider.executeAutomaticEmergencyWorkflow(source: 'manual_confirm');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeWordPromptContent(
    BuildContext context,
    EmergencySosProvider provider,
    String userId,
  ) {
    final theme = Theme.of(context);

    return AdiuvaCard(
      padding: AdiuvaSpacing.paddingLg,
      backgroundColor: Colors.deepOrange.shade50,
      child: Column(
        children: [
          Text(
            'Emergency Code Word Verification',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          AdiuvaSpacing.gapMd,
          Text(
            'Say your emergency code word aloud, or type it below to complete SOS activation:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.deepOrange.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          AdiuvaSpacing.gapLg,
          TextField(
            controller: _codeWordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Emergency Code Word',
              hintText: 'Enter code word',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (val) {
              provider.verifyCodeWordAndSend(val, userId);
            },
          ),
          AdiuvaSpacing.gapLg,
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
                  label: 'Verify & Send',
                  onPressed: () {
                    provider.verifyCodeWordAndSend(_codeWordController.text, userId);
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
          'Acquiring Location & Transmitting SOS Alert...',
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
    final phone = provider.getEffectiveEmergencyPhone();

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
                'SOS Workflow Activated',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Emergency contact ($phone) has been notified with your current GPS coordinates.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapMd,
              const Divider(),
              AdiuvaSpacing.gapSm,

              // SMS Status Item
              Row(
                children: [
                  Icon(
                    provider.smsStatus == SosSmsStatus.sent
                        ? Icons.check_circle_rounded
                        : (provider.smsStatus == SosSmsStatus.permissionDenied
                            ? Icons.warning_rounded
                            : Icons.sms_rounded),
                    color: provider.smsStatus == SosSmsStatus.sent
                        ? Colors.green.shade700
                        : (provider.smsStatus == SosSmsStatus.permissionDenied
                            ? Colors.amber.shade800
                            : AdiuvaColors.error),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.smsStatusMessage ??
                          (provider.smsStatus == SosSmsStatus.sent
                              ? 'Direct SMS sent with map location.'
                              : 'SMS status recorded.'),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              AdiuvaSpacing.gapSm,

              // Phone Call Status Item
              Row(
                children: [
                  Icon(
                    provider.callStatus == SosCallStatus.initiated
                        ? Icons.check_circle_rounded
                        : (provider.callStatus == SosCallStatus.permissionDenied
                            ? Icons.warning_rounded
                            : Icons.phone_in_talk_rounded),
                    color: provider.callStatus == SosCallStatus.initiated
                        ? Colors.green.shade700
                        : (provider.callStatus == SosCallStatus.permissionDenied
                            ? Colors.amber.shade800
                            : AdiuvaColors.error),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.callStatusMessage ??
                          (provider.callStatus == SosCallStatus.initiated
                              ? 'Emergency call initiated to contact.'
                              : 'Call status recorded.'),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
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
                onPressed: () => provider.executeAutomaticEmergencyWorkflow(userId: userId, source: 'manual_retry'),
              ),
            ),
          ],
        ),
        AdiuvaSpacing.gapMd,
        CustomButton.secondary(
          label: 'Call Emergency Services (112)',
          leadingIcon: Icons.phone_in_talk_rounded,
          onPressed: () async {
            final uri = Uri.parse('tel:112');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
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

  void _showEditSettingsDialog(BuildContext context, EmergencySosProvider provider) {
    final nameCtrl = TextEditingController(text: provider.contactName);
    final phoneCtrl = TextEditingController(text: provider.contactPhone);
    final codeWordCtrl = TextEditingController(text: provider.emergencyCodeWord);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Emergency Contact & Code Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                hintText: 'e.g. Caregiver Name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Phone',
                hintText: '+1234567890',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeWordCtrl,
              decoration: const InputDecoration(
                labelText: 'Shake Emergency Code Word',
                hintText: 'e.g. red alert, safe, help',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await provider.updateEmergencySettings(
                nameCtrl.text,
                phoneCtrl.text,
                codeWordCtrl.text,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
