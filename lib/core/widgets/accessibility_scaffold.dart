import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../theme/adiuva_spacing.dart';
import '../../features/speech_assistance/presentation/provider/global_voice_control_provider.dart';
import '../../features/speech_assistance/presentation/widgets/global_voice_fab.dart';

/// ADIUVA Accessibility Scaffold
/// 
/// Accessibility-first Scaffold wrapper that ensures:
/// - Semantic screen labeling for screen readers
/// - Logical focus traversal order
/// - Live-region announcements when requested
/// - Safe area compliance
/// - Standardized padding and high-contrast support
/// - Compulsory Global Voice control FAB on all non-splash screens
class AccessibilityScaffold extends StatelessWidget {
  /// Title of the page for screen reader semantic announcements
  final String pageTitle;

  /// Optional custom AppBar widget
  final PreferredSizeWidget? appBar;

  /// Main page body
  final Widget body;

  /// Optional bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional floating action button location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional padding override around body
  final EdgeInsetsGeometry? padding;

  /// Optional semantic announcement when page loads
  final String? initialAnnouncement;

  const AccessibilityScaffold({
    super.key,
    required this.pageTitle,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.padding,
    this.initialAnnouncement,
  });

  /// Static helper method to trigger screen reader live-region announcement
  static void announce(String message) {
    if (message.isNotEmpty) {
      // ignore: deprecated_member_use
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialAnnouncement != null && initialAnnouncement!.isNotEmpty) {
        announce(initialAnnouncement!);
      }
      try {
        final voice = Provider.of<GlobalVoiceControlProvider>(context, listen: false);
        voice.setScreenContext(context, pageTitle);
        final title = pageTitle.toLowerCase();
        if (title != 'splash screen' && title != 'splash') {
          voice.initAppVoiceStartup(context);
        }
      } catch (_) {}
    });

    final title = pageTitle.toLowerCase();
    final isSplash = title == 'splash screen' || title == 'splash';
    final effectiveFab = isSplash
        ? null
        : (floatingActionButton != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  floatingActionButton!,
                  AdiuvaSpacing.gapSm,
                  const GlobalVoiceFab(),
                ],
              )
            : const GlobalVoiceFab());

    return Semantics(
      label: '$pageTitle screen',
      explicitChildNodes: true,
      child: Scaffold(
        backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        appBar: appBar,
        body: SafeArea(
          child: Padding(
            padding: padding ?? AdiuvaSpacing.pagePadding,
            child: body,
          ),
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: effectiveFab,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}
