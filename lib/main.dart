import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/di/service_locator.dart';
import 'core/theme/adiuva_theme.dart';
import 'core/theme/adiuva_spacing.dart';
import 'core/widgets/accessibility_scaffold.dart';
import 'core/widgets/custom_app_bar.dart';
import 'core/widgets/custom_button.dart';
import 'core/widgets/adiuva_card.dart';
import 'config/routes/app_routes.dart';
import 'config/routes/route_generator.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'features/speech_assistance/presentation/provider/speech_assistance_provider.dart';
import 'features/speech_assistance/presentation/provider/voice_mode_provider.dart';
import 'features/visual_assistance/presentation/provider/visual_assistance_provider.dart';
import 'features/accessibility/presentation/provider/accessibility_provider.dart';
import 'features/emergency_sos/presentation/provider/emergency_sos_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure App Check: AndroidDebugProvider in debug mode, AndroidPlayIntegrityProvider in release
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
  );

  // Print existing App Check token non-blockingly in debug mode
  if (kDebugMode) {
    FirebaseAppCheck.instance.getToken(false).then((token) {
      debugPrint('====================================================');
      debugPrint('ADIUVA FIREBASE APP CHECK TOKEN: $token');
      debugPrint('====================================================');
    }).catchError((e) {
      debugPrint('Firebase App Check token info: $e');
    });
  }

  // Initialize Dependency Injection (GetIt)
  await setupServiceLocator();

  runApp(const AdiuvaApp());
}

class AdiuvaApp extends StatelessWidget {
  const AdiuvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => sl<AuthProvider>(),
        ),
        ChangeNotifierProvider<AccessibilityProvider>(
          create: (_) => sl<AccessibilityProvider>(),
        ),
        ChangeNotifierProvider<EmergencySosProvider>(
          create: (_) => sl<EmergencySosProvider>(),
        ),
        ChangeNotifierProvider<SpeechAssistanceProvider>(
          create: (_) => sl<SpeechAssistanceProvider>(),
        ),
        ChangeNotifierProvider<VoiceModeProvider>(
          create: (_) => sl<VoiceModeProvider>(),
        ),
        ChangeNotifierProvider<VisualAssistanceProvider>(
          create: (_) => sl<VisualAssistanceProvider>(),
        ),
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Adiuva',
            theme: settings.isHighContrast
                ? AdiuvaTheme.highContrastLightTheme
                : AdiuvaTheme.lightTheme,
            darkTheme: settings.isHighContrast
                ? AdiuvaTheme.highContrastDarkTheme
                : AdiuvaTheme.darkTheme,
            themeMode: settings.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: RouteGenerator.generateRoute,
          );
        },
      ),
    );
  }
}

class GeminiTestPage extends StatefulWidget {
  const GeminiTestPage({super.key});

  @override
  State<GeminiTestPage> createState() => _GeminiTestPageState();
}

class _GeminiTestPageState extends State<GeminiTestPage> {
  String responseText = 'Tap the button below to test Gemini AI.';
  bool isLoading = false;

  Future<void> testGemini() async {
    setState(() {
      isLoading = true;
      responseText = 'Gemini is thinking...';
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );

      final response = await model.generateContent([
        Content.text('Say hello to Adiuva in one short sentence.')
      ]).timeout(const Duration(seconds: 15));

      setState(() {
        responseText = response.text ?? 'No response received.';
      });
    } catch (e) {
      setState(() {
        responseText = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityScaffold(
      pageTitle: 'Adiuva Design System & Gemini AI Test',
      appBar: const CustomAppBar(
        title: 'ADIUVA',
        showBackButton: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gemini AI & Design System Test',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapLg,
              AdiuvaCard(
                semanticLabel: 'Gemini AI Response Box',
                child: Padding(
                  padding: AdiuvaSpacing.paddingLg,
                  child: Column(
                    children: [
                      Text(
                        responseText,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              AdiuvaSpacing.gapXl,
              CustomButton.primary(
                label: 'Test Gemini AI',
                isLoading: isLoading,
                leadingIcon: Icons.auto_awesome,
                onPressed: testGemini,
              ),
              AdiuvaSpacing.gapMd,
              CustomButton.voiceAction(
                label: 'Voice Assistant Action (Sand Mode)',
                leadingIcon: Icons.mic_none_outlined,
                onPressed: () {
                  AccessibilityScaffold.announce('Voice Assistant action triggered');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}