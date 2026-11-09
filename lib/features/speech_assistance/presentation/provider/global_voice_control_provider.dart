// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/services/voice_response_localizer.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../features/accessibility/presentation/provider/accessibility_provider.dart';
import '../../../../features/auth/presentation/provider/auth_provider.dart';
import '../../../../features/visual_assistance/presentation/provider/visual_assistance_provider.dart';
import '../../../../features/visual_assistance/domain/entities/vision_result.dart';
import '../../../../features/physical_assistance/presentation/provider/physical_assistance_provider.dart';
import '../../../../features/cognitive_assistance/presentation/provider/todo_provider.dart';
import '../../../../features/emergency_sos/presentation/provider/emergency_sos_provider.dart';
import '../../../../features/sign_language/data/registries/sign_language_phrase_registry.dart';
import '../../../../features/sign_language/presentation/provider/sign_language_provider.dart';
import '../../domain/entities/voice_action.dart';
import '../../data/datasources/voice_action_registry.dart';

/// Explicit Global Voice Control State Machine Model
enum GlobalVoiceState {
  idle,
  listening,
  processingCommand,
  speaking,
  yieldedToFeature,
  stopped,
  error,
}

/// Centralized Voice-First Global Engine for All ADiUVA Users
class GlobalVoiceControlProvider extends ChangeNotifier {
  final SttService _sttService;
  final TtsService _ttsService;
  final VoiceActionRegistry _actionRegistry = VoiceActionRegistry();

  GlobalVoiceState _state = GlobalVoiceState.idle;
  String _lastCommand = '';
  String _lastTtsOutput = '';
  String _displayTranscript = '';
  String _lastExecutedCommand = '';
  DateTime? _lastExecutedTime;
  String? _errorMessage;
  bool _isExecutingCommand = false;
  bool _isAutoVoiceEnabled = true;
  bool _isYieldedToFeature = false;
  bool _isAppStartupCompleted = false;
  bool _hasStartedSttAfterWelcome = false;
  Timer? _welcomeFallbackTimer;
  VoidCallback? _onWelcomeTtsCallback;
  int _consecutiveSilenceCount = 0;
  int _consecutiveUnrecognizedCount = 0;
  String _currentScreenContext = 'home';
  String _currentLanguageCode = 'en';
  String _recentTtsOutput = '';
  DateTime? _lastTtsFinishedTime;
  DateTime? _lastLanguageSwitchTime;
  BuildContext? _activeContext;

  /// Safely retrieve stable application BuildContext for global provider access
  BuildContext? get _safeGlobalContext {
    final rootCtx = AppRoutes.navigatorKey.currentContext;
    if (rootCtx != null && rootCtx.mounted) {
      return rootCtx;
    }
    if (_activeContext != null && _activeContext!.mounted) {
      return _activeContext;
    }
    return null;
  }

  GlobalVoiceControlProvider({
    required SttService sttService,
    required TtsService ttsService,
  })  : _sttService = sttService,
        _ttsService = ttsService {
    _ttsService.setCompletionListener(_onTtsPlaybackFinished);
    _ttsService.addListener(_onTtsStateChanged);
    _registerAllScreenActions();
  }

  void _onTtsStateChanged() {
    if (_ttsService.isSpeaking) {
      debugPrint('[VOICE_DEVICE] TTS speaking = true');
      // When TTS is actively speaking from the device loudspeaker, ensure STT is stopped
      // so the microphone does not record the app's own speech output and cause echo loops.
      if (_sttService.isListening) {
        _sttService.stopListening();
      }
    }
  }

  GlobalVoiceState get state => _state;
  String get lastCommand => _lastCommand;
  String get lastTtsOutput => _lastTtsOutput;
  String? get errorMessage => _errorMessage;
  bool get isListening => _state == GlobalVoiceState.listening;
  bool get isSpeaking => _state == GlobalVoiceState.speaking;
  bool get isAutoVoiceEnabled => _isAutoVoiceEnabled;
  bool get isYieldedToFeature => _isYieldedToFeature;
  String get currentLanguageCode => _currentLanguageCode;
  int get consecutiveSilenceCount => _consecutiveSilenceCount;

  String get displayTranscript {
    if (_displayTranscript.trim().isNotEmpty) {
      return _displayTranscript.trim();
    }
    if (_state == GlobalVoiceState.speaking && _lastTtsOutput.isNotEmpty) {
      return _lastTtsOutput;
    }
    if (_state == GlobalVoiceState.processingCommand) {
      return 'Processing...';
    }
    if (_state == GlobalVoiceState.error) {
      return _errorMessage ?? 'Voice unavailable';
    }
    if (_state == GlobalVoiceState.yieldedToFeature) {
      return 'Paused';
    }
    if (_state == GlobalVoiceState.stopped) {
      return 'Stopped';
    }
    return 'Listening...';
  }

  Future<void> changeLanguage(String targetCode, {BuildContext? context}) async {
    _currentLanguageCode = targetCode;
    _lastLanguageSwitchTime = DateTime.now();
    final ctx = context ?? _safeGlobalContext;
    if (ctx != null && ctx.mounted) {
      try {
        final accProvider = Provider.of<AccessibilityProvider>(ctx, listen: false);
        await accProvider.setAppLanguage(targetCode);
      } catch (_) {}
    }
    _guardedRecoveryTimer?.cancel();
    _guardedRecoveryTimer = null;
    await _sttService.stopListening();
    final locale = VoiceResponseLocalizer.normalizeLocale(targetCode);
    await _ttsService.setLanguage(locale);
    final confirmationMsg = VoiceResponseLocalizer.languageChangedConfirmation(locale);
    _recentTtsOutput = confirmationMsg;
    _lastTtsOutput = confirmationMsg;
    await speakConfirmation(confirmationMsg);
  }

  /// Helper method for explicit state transitions with structured logging
  void _setVoiceState(GlobalVoiceState newState, {String? reason}) {
    if (_state != newState) {
      debugPrint('[VOICE_STATE] State change: $_state -> $newState${reason != null ? " ($reason)" : ""}');
      debugPrint('[VOICE_RUNTIME] status = ${newState.name}');
      _state = newState;
      notifyListeners();
    }
  }

  bool _hasSpokenReturningWelcome = false;

  /// Update active screen context and trigger auto-voice guidance if enabled
  void setScreenContext(BuildContext context, String contextName) {
    _activeContext = context;
    final newContext = contextName.toLowerCase().trim();
    if (_currentScreenContext != newContext) {
      debugPrint('[VOICE_NAV] Screen context changed: $_currentScreenContext -> $newContext');
      _currentScreenContext = newContext;
      _consecutiveSilenceCount = 0;
      _consecutiveUnrecognizedCount = 0;

      // Speak returning user greeting when landing on Home Dashboard if not yet spoken
      if ((newContext.contains('home') || newContext.contains('dashboard')) &&
          _isAppStartupCompleted &&
          !_hasSpokenReturningWelcome &&
          !_ttsService.isSpeaking &&
          _state != GlobalVoiceState.speaking) {
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isAuthenticated) {
            _hasSpokenReturningWelcome = true;
            final user = authProvider.user;
            final prefName = (user?.preferredName != null && user!.preferredName!.trim().isNotEmpty)
                ? user.preferredName!.trim()
                : (user?.name != null && user!.name.trim().isNotEmpty ? user.name.trim() : 'User');
            final locale = VoiceResponseLocalizer.normalizeLocale(_currentLanguageCode);
            final msg = VoiceResponseLocalizer.returningWelcome(locale, prefName);
            Future.microtask(() => speakConfirmation(msg));
          }
        } catch (_) {}
      }
    }
  }

  /// Reset voice flags upon sign out
  void resetVoiceStateForSignout() {
    _isAppStartupCompleted = false;
    _hasSpokenReturningWelcome = false;
    _sttService.stopListening();
    _ttsService.stop();
    _setVoiceState(GlobalVoiceState.idle, reason: "Reset for sign out");
  }

  /// Start STT after welcome completion (or fallback)
  void _startSttPostWelcome(String triggerSource) async {
    if (_hasStartedSttAfterWelcome) return;
    _hasStartedSttAfterWelcome = true;

    _welcomeFallbackTimer?.cancel();
    _welcomeFallbackTimer = null;

    if (_onWelcomeTtsCallback != null) {
      _ttsService.removeCompletionListener(_onWelcomeTtsCallback!);
      _onWelcomeTtsCallback = null;
    }

    debugPrint('[VOICE_FINAL] welcome completed');
    debugPrint('[VOICE_STARTUP] welcome TTS completed (trigger: $triggerSource)');
    debugPrint('[VOICE_DEVICE] TTS speaking = false');
    debugPrint('[VOICE_STARTUP] waiting 500ms before starting STT');
    await Future.delayed(const Duration(milliseconds: 500));

    // Ensure any stale STT session is stopped cleanly
    await _sttService.stopListening();
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint('[VOICE_DEVICE] starting STT');
    debugPrint('[VOICE_STARTUP] starting STT');
    final ctx = _safeGlobalContext;
    if (ctx != null && ctx.mounted && _isAutoVoiceEnabled && !_isYieldedToFeature) {
      await triggerAutoListening(ctx);
    }
  }

  /// Explicit Voice-First App Startup (Fired once on the first non-splash screen frame)
  Future<void> initAppVoiceStartup(BuildContext context) async {
    if (_isAppStartupCompleted) {
      return;
    }
    _isAppStartupCompleted = true;
    _hasSpokenReturningWelcome = true;
    _activeContext = context;

    debugPrint('[VOICE_FINAL] startup');
    debugPrint('[VOICE_STARTUP] app startup triggered');
    debugPrint('[VOICE_RUNTIME] startup entered');
    debugPrint('[VOICE_STATE] initAppVoiceStartup entered');

    String locale = 'en-IN';
    _currentLanguageCode = 'en'; // Fresh app launch always begins in English

    // 1. Check & Request Microphone Permission UPFRONT before Welcome
    var status = await Permission.microphone.status;
    debugPrint('[VOICE_FINAL] microphone permission = $status');
    debugPrint('[VOICE_RUNTIME] microphone permission = $status');
    if (!status.isGranted) {
      debugPrint('[VOICE_STT] Requesting microphone permission');
      status = await Permission.microphone.request();
      debugPrint('[VOICE_FINAL] microphone permission = $status');
      debugPrint('[VOICE_RUNTIME] microphone permission after request = $status');
    }

    if (!status.isGranted) {
      debugPrint('[VOICE_RUNTIME] microphone permission denied');
      _isAutoVoiceEnabled = false;
      _setVoiceState(GlobalVoiceState.error, reason: "Microphone permission denied");
      await speakConfirmation(VoiceResponseLocalizer.micPermissionRequired(locale));
      return;
    }

    // 2. Initialize STT Engine
    debugPrint('[VOICE_RUNTIME] STT initialize entered');
    final isAvailable = await _sttService.initialize();
    debugPrint('[VOICE_FINAL] STT initialized = $isAvailable');
    debugPrint('[VOICE_RUNTIME] STT initialize result = $isAvailable');
    debugPrint('[VOICE_RUNTIME] speech available = $isAvailable');

    if (!isAvailable) {
      debugPrint('[VOICE_RUNTIME] Speech recognition engine unavailable');
      _setVoiceState(GlobalVoiceState.error, reason: "STT unavailable");
      await speakConfirmation(VoiceResponseLocalizer.speechUnavailable(locale));
      return;
    }

    // 3. Welcome TTS with completion listener & guarded fallback timer
    _hasStartedSttAfterWelcome = false;

    _onWelcomeTtsCallback = () => _startSttPostWelcome('TTS completion callback');
    _ttsService.addCompletionListener(_onWelcomeTtsCallback!);

    // Guarded fallback timer: 3800ms
    _welcomeFallbackTimer = Timer(const Duration(milliseconds: 3800), () {
      debugPrint('[VOICE_STARTUP] Fallback timer fired');
      _startSttPostWelcome('Fallback timer (3.8s)');
    });

    final screenCtx = _currentScreenContext.toLowerCase();
    final isSignInOrSignUpPage = screenCtx.contains('sign in') ||
        screenCtx.contains('login') ||
        screenCtx.contains('sign up') ||
        screenCtx.contains('signup');

    String welcomeMsg;
    final safeCtx = _safeGlobalContext;
    if (isSignInOrSignUpPage) {
      welcomeMsg = VoiceResponseLocalizer.welcomeMessage(locale);
    } else if (safeCtx != null && safeCtx.mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(safeCtx, listen: false);
        if (authProvider.isAuthenticated) {
          final user = authProvider.user;
          final prefName = user?.greetingName ?? 'User';
          debugPrint('[AUTH_TRACE] greeting_name=$prefName');
          welcomeMsg = VoiceResponseLocalizer.returningWelcome(locale, prefName);
        } else {
          welcomeMsg = VoiceResponseLocalizer.welcomeMessage(locale);
        }
      } catch (_) {
        welcomeMsg = VoiceResponseLocalizer.welcomeMessage(locale);
      }
    } else {
      welcomeMsg = VoiceResponseLocalizer.welcomeMessage(locale);
    }

    debugPrint('[VOICE_FINAL] welcome started');
    debugPrint('[VOICE_STARTUP] welcome TTS started: "$welcomeMsg"');
    try {
      await speakConfirmation(welcomeMsg);
    } catch (e) {
      debugPrint('[VOICE_RUNTIME] TTS ERROR speaking welcome: $e');
      _startSttPostWelcome('TTS error fallback');
    }
  }

  /// Temporarily yield microphone to feature screens (e.g., Hearing Assistance / Voice Mode)
  Future<void> yieldMicrophoneToFeature(bool shouldYield) async {
    debugPrint('[VOICE_STATE] yieldMicrophoneToFeature($shouldYield) requested. Current state: $_state');
    _isYieldedToFeature = shouldYield;
    if (shouldYield) {
      await _sttService.stopListening();
      await _ttsService.stop();
      _isExecutingCommand = false;
      _setVoiceState(GlobalVoiceState.yieldedToFeature, reason: "Yielded to feature");
      debugPrint('[VOICE_STT] Global voice yielded to feature screen');
    } else {
      _setVoiceState(GlobalVoiceState.idle, reason: "Unyielded from feature");
      debugPrint('[VOICE_STT] Global voice unyielded from feature screen');
      final ctx = _safeGlobalContext;
      if (ctx != null && ctx.mounted && _isAutoVoiceEnabled) {
        debugPrint('[VOICE_RUNTIME] auto-restart requested after unyield');
        Future.microtask(() => triggerAutoListening(ctx));
      }
    }
  }

  /// Internal callback fired automatically when TTS finishes speaking
  void _onTtsPlaybackFinished() {
    debugPrint('[VOICE_RUNTIME] TTS completed');
    debugPrint('[VOICE_DEVICE] TTS speaking = false');
    _isExecutingCommand = false;
    if (_lastTtsOutput.trim().isNotEmpty) {
      _recentTtsOutput = _lastTtsOutput;
    }
    _lastTtsFinishedTime = DateTime.now();
    _lastTtsOutput = '';
    
    // Always transition to idle upon TTS completion
    _setVoiceState(GlobalVoiceState.idle, reason: "TTS finished");

    // Defer post-welcome STT startup strictly to _startSttPostWelcome to prevent duplicate sessions on launch
    if (!_hasStartedSttAfterWelcome && _onWelcomeTtsCallback != null) {
      debugPrint('[VOICE_STARTUP] Initial welcome TTS completion handled by _startSttPostWelcome');
      return;
    }

    if (_isAutoVoiceEnabled && !_isYieldedToFeature && _state != GlobalVoiceState.listening) {
      debugPrint('[VOICE_RUNTIME] auto-restart requested after TTS playback completion (400ms cooldown)');
      _scheduleGuardedRecovery(delayMs: 400);
    }
  }

  /// Trigger TTS speech with clean microphone silencing during confirmation
  Future<void> speakConfirmation(String text) async {
    _lastTtsOutput = text;
    _recentTtsOutput = text;
    _lastTtsFinishedTime = DateTime.now();
    _setVoiceState(GlobalVoiceState.speaking, reason: "Speaking confirmation");
    debugPrint('[VOICE_DEVICE] TTS speaking = true');

    debugPrint('[VOICE_RUNTIME] TTS started: "$text"');

    // Ensure STT is stopped while confirmation TTS is speaking to prevent speaker/mic feedback
    await _sttService.stopListening();

    final ttsSpeechText = text.contains('\n') ? text.split('\n').first.trim() : text;
    await _ttsService.speak(ttsSpeechText);
  }

  void _registerAllScreenActions() {
    _actionRegistry.registerActions([
      const VoiceAction(
        id: 'google_sign_in',
        label: 'Continue with Google',
        screenContext: 'auth',
        aliases: [
          'sign in with google',
          'google sign in',
          'continue with google',
          'google login',
          'sign in google',
          'google signin',
          'login with google'
        ],
      ),
      const VoiceAction(
        id: 'login',
        label: 'Sign In',
        screenContext: 'auth',
        aliases: ['sign in', 'login', 'log in'],
      ),
      const VoiceAction(
        id: 'signup',
        label: 'Sign Up',
        screenContext: 'auth',
        aliases: ['sign up', 'signup', 'register', 'create account'],
      ),
      const VoiceAction(
        id: 'open_visual_assistance',
        label: 'Visual Assistance',
        screenContext: 'global',
        aliases: [
          'open visual assistance',
          'visual assistance',
          'open the visual assistance',
          'open visual assistant',
          'visual assistant',
          'open visual',
          'visual mode',
          'open visual mode',
          'open blind assistance',
          'blind assistance',
          'blind mode',
          'open blind mode',
          'blind dashboard',
          'open blind dashboard',
          'vision mode',
          'open vision mode',
          'vision assistant',
          'open vision assistant',
          'vision assistance',
          'open vision assistance',
          'open vision',
          'vision',
          'open visual helper',
          'visual helper',
          'open visual support',
          'visual support',
          'open eye helper',
          'eye helper',
          'camera assistance',
          'open camera assistance',
          'drishti sahaita',
          'drishti sahayata',
          'दृष्टि सहायता',
          'विजुअल असिस्टेंस',
          'please open visual assistance',
          'can you open visual assistance',
          'could you please open visual assistance for me',
          'i want to use visual assistance',
          'visual assistance open pannunga',
          'பார்வை உதவி',
          'விஷுவல் அசிஸ்டென்ஸ்',
          'visual assistance open cheyyi',
          'దృష్టి సహాయం',
          'విజ్యువల్ అసిస్టెన్స్',
          'visual assistance open maadi',
          'ದೃಷ್ಟಿ ನೆರವು',
          'ವಿಷುವಲ್ ಅಸಿಸ್ಟೆನ್ಸ್'
        ],
      ),
      const VoiceAction(
        id: 'open_hearing_assistance',
        label: 'Hearing Assistance',
        screenContext: 'global',
        aliases: [
          'open hearing assistance',
          'hearing assistance',
          'open deaf assistance',
          'deaf assistance',
          'deaf mode',
          'hearing mode',
          'hearing helper',
          'open hearing helper',
          'shravan sahayata',
          'ಶ್ರವಣ ಸಹಾಯ',
          'श्रवण सहायता',
          'हियरिंग असिस्टेंस',
          'please open hearing assistance',
          'hearing assistance open pannunga',
          'செவிப்புலன் உதவி',
          'hearing assistance open cheyyi',
          'హియరింగ్ అసిస్టెన్స్',
          'hearing assistance open maadi',
          'ಶ್ರವಣ ನೆರವು'
        ],
      ),
      const VoiceAction(
        id: 'open_cognitive_assistance',
        label: 'Cognitive Assistance',
        screenContext: 'global',
        aliases: [
          'open cognitive assistance',
          'cognitive assistance',
          'open the cognitive assistance',
          'open cognitive assistant',
          'cognitive assistant',
          'cognativ assistance',
          'cognative assistance',
          'open cognative assistance',
          'cognative assistant',
          'open cognative assistant',
          'cognative',
          'open cognative',
          'cognition assistance',
          'open cognition assistance',
          'cognition assistant',
          'open cognition assistant',
          'cognition',
          'open cognition',
          'cognitive mode',
          'open cognitive mode',
          'cognitive support',
          'open cognitive support',
          'memory assistant',
          'open memory assistant',
          'memory assistance',
          'open memory assistance',
          'memory mode',
          'open memory mode',
          'cognitive helper',
          'open cognitive helper',
          'cognitive',
          'open cognitive',
          'कॉग्निटिव असिस्टेंस',
          'please open cognitive assistance',
          'cognitive assistance open pannunga',
          'அறிவாற்றல் உதவி',
          'cognitive assistance open cheyyi',
          'కాగ్నిటివ్ అసిస్టెన్స్',
          'cognitive assistance open maadi',
          'ಕಾಗ್ನಿಟಿವ್ ನೆರವು'
        ],
      ),
      const VoiceAction(
        id: 'open_physical_assistance',
        label: 'Physical Assistance',
        screenContext: 'global',
        aliases: [
          'open physical',
          'open physical assistance',
          'physical assistance',
          'open physical assistant',
          'physical assistant',
          'open physical mode',
          'fiscal assistance',
          'physicle assistance',
          'physical mode',
          'motor mode',
          'physical helper',
          'physical',
          'मोटर मोड',
          'फिजिकल असिस्टेंस',
          'please open physical assistance',
          'physical assistance open pannunga',
          'உடல் உதவி',
          'physical assistance open cheyyi',
          'ఫిజికల్ అసిస్టెన్స్',
          'physical assistance open maadi',
          'ದೈಹಿಕ ನೆರವು'
        ],
      ),
      const VoiceAction(
        id: 'open_normal_user',
        label: 'Normal User Suite',
        screenContext: 'global',
        aliases: [
          'open normal user',
          'normal user',
          'open normal mode',
          'normal mode',
          'general mode'
        ],
      ),
      const VoiceAction(
        id: 'open_sign_language',
        label: 'Sign Language',
        screenContext: 'global',
        aliases: [
          'open sign language',
          'sign language',
          'open sign language avatar',
          'sign language avatar',
          'isl avatar',
          'isl'
        ],
      ),
      const VoiceAction(
        id: 'open_sign_to_text',
        label: 'Sign Language to Text',
        screenContext: 'global',
        aliases: [
          'open sign language to text',
          'sign language to text',
          'open sign to text',
          'sign to text',
          'sign recognition',
          'camera sign language',
          'recognize signs'
        ],
      ),
      const VoiceAction(
        id: 'open_text_to_sign',
        label: 'Text to Sign Language',
        screenContext: 'global',
        aliases: [
          'open text to sign language',
          'text to sign language',
          'open text to sign',
          'text to sign',
          'sign demonstration',
          'show sign language',
          'avatar sign language'
        ],
      ),
      const VoiceAction(
        id: 'object_detection',
        label: 'Object Detection',
        screenContext: 'global',
        aliases: [
          'open object detection',
          'object detection',
          'detect objects',
          'identify object',
          'open object detector',
          'object detector',
          'objects detection',
          'detect object'
        ],
      ),
      const VoiceAction(
        id: 'ocr',
        label: 'Read Text',
        screenContext: 'global',
        aliases: [
          'open ocr',
          'ocr',
          'open read text',
          'read text',
          'text reader',
          'scan text'
        ],
      ),
      const VoiceAction(
        id: 'scene_description',
        label: 'Scene Description',
        screenContext: 'global',
        aliases: [
          'open scene description',
          'scene description',
          'describe surroundings',
          'describe scene'
        ],
      ),
      const VoiceAction(
        id: 'document_reader',
        label: 'Document Reader',
        screenContext: 'global',
        aliases: [
          'document reader',
          'open document reader',
          'read document',
          'open document'
        ],
      ),
      const VoiceAction(
        id: 'import_document',
        label: 'Import Document',
        screenContext: 'visual_assistance',
        aliases: [
          'import document',
          'open document',
          'load document',
          'import story',
          'select document',
          'import'
        ],
      ),
      const VoiceAction(
        id: 'start_reading',
        label: 'Start Reading',
        screenContext: 'visual_assistance',
        aliases: [
          'start',
          'start reading',
          'read aloud',
          'begin reading',
          'play',
          'read this',
          'read story',
          'read page'
        ],
      ),
      const VoiceAction(
        id: 'pause_reading',
        label: 'Pause Reading',
        screenContext: 'visual_assistance',
        aliases: [
          'pause',
          'pause reading',
          'pause story'
        ],
      ),
      const VoiceAction(
        id: 'resume_reading',
        label: 'Resume Reading',
        screenContext: 'visual_assistance',
        aliases: [
          'resume',
          'resume reading',
          'continue reading',
          'continue'
        ],
      ),
      const VoiceAction(
        id: 'stop_reading',
        label: 'Stop Reading',
        screenContext: 'visual_assistance',
        aliases: [
          'stop reading',
          'stop story'
        ],
      ),
      const VoiceAction(
        id: 'next_page',
        label: 'Next Page',
        screenContext: 'visual_assistance',
        aliases: [
          'next page',
          'go to next page',
          'next',
          'page next'
        ],
      ),
      const VoiceAction(
        id: 'previous_page',
        label: 'Previous Page',
        screenContext: 'visual_assistance',
        aliases: [
          'previous page',
          'go back one page',
          'previous',
          'page back'
        ],
      ),
      const VoiceAction(
        id: 'story_summary',
        label: 'What is this story about?',
        screenContext: 'visual_assistance',
        aliases: [
          'what is this story about',
          'summarize story',
          'summarize document',
          'story summary',
          'tell me the story'
        ],
      ),
      const VoiceAction(
        id: 'open_daily_tasks',
        label: 'Daily Tasks',
        screenContext: 'global',
        aliases: ['open daily tasks', 'open tasks', 'daily tasks', 'task list', 'my tasks'],
      ),
      const VoiceAction(
        id: 'add_task',
        label: 'Add Task',
        screenContext: 'global',
        aliases: ['add task', 'add a task', 'create task', 'create a task', 'add'],
      ),
      const VoiceAction(
        id: 'complete_task',
        label: 'Complete Task',
        screenContext: 'global',
        aliases: ['complete task', 'complete a task', 'complete', 'mark complete'],
      ),
      const VoiceAction(
        id: 'delete_task',
        label: 'Delete Task',
        screenContext: 'global',
        aliases: ['delete task', 'delete a task', 'delete', 'remove task'],
      ),
      const VoiceAction(
        id: 'open_reminders',
        label: 'Reminders & Medication',
        screenContext: 'global',
        aliases: ['open reminders', 'reminders', 'medication', 'reminders open pannunga', 'நினைவூட்டல்கள்', 'reminders open cheyyi', 'రిమైండర్లు', 'reminders open maadi', 'ಜ್ಞಾಪನೆಗಳು'],
      ),
      const VoiceAction(
        id: 'add_reminder',
        label: 'Add Reminder',
        screenContext: 'global',
        aliases: ['add reminder', 'create reminder', 'new reminder'],
      ),
      const VoiceAction(
        id: 'add_medication',
        label: 'Add Medication',
        screenContext: 'global',
        aliases: ['add medication reminder', 'add medication', 'medication reminder'],
      ),
      const VoiceAction(
        id: 'open_notes',
        label: 'Notes & Memory',
        screenContext: 'global',
        aliases: ['open notes', 'notes', 'memory notes', 'notes open pannunga', 'குறிப்புகள்', 'notes open cheyyi', 'నోట్స్', 'notes open maadi', 'ಟಿಪ್ಪಣಿಗಳು'],
      ),
      const VoiceAction(
        id: 'add_note',
        label: 'Add Note',
        screenContext: 'global',
        aliases: ['add note', 'create note', 'save note', 'new note'],
      ),
      const VoiceAction(
        id: 'call_caregiver',
        label: 'Call Caregiver',
        screenContext: 'global',
        aliases: ['call caregiver', 'call my caregiver', 'open caregiver', 'set caregiver', 'phone caregiver', 'contact caregiver', 'call helper', 'i need to call my caregiver', 'caregiver-ukku call pannu', 'கேர்கிவரை கூப்பிடு', 'caregiver ki call cheyyi', 'కేర్‌గివర్‌కి కాల్ చేయి', 'caregiver ge call maadi', 'ಕೇರ್‌ಗಿವರ್‌ಗೆ ಕಾಲ್ ಮಾಡಿ'],
      ),
      const VoiceAction(
        id: 'open_calendar',
        label: 'Calendar',
        screenContext: 'global',
        aliases: ['open calendar', 'calendar', 'view calendar', 'my schedule', 'calendar open pannunga', 'நாட்காட்டி', 'calendar open cheyyi', 'క్యాలెండర్', 'calendar open maadi', 'ಕ್ಯಾಲೆಂಡರ್'],
      ),
      const VoiceAction(
        id: 'open_translator',
        label: 'Translator',
        screenContext: 'global',
        aliases: ['open translator', 'translator', 'translate', 'live translation', 'translate this', 'translator open pannunga', 'மொழிபெயர்ப்பு', 'translator open cheyyi', 'అనువాదం', 'translator open maadi', 'ಅನುವಾದ'],
      ),
      const VoiceAction(
        id: 'open_location',
        label: 'Location',
        screenContext: 'global',
        aliases: [
          'open location',
          'location screen',
          'location page',
          'where am i screen',
          'where am i',
          'what is my location',
          'tell me my location',
          'my current location',
          'current location',
          'show my location',
          'where am i right now',
          'please tell me where i am',
          'could you please tell me my current location',
          'can you tell me where i am',
          'show location',
          'tell my location',
          'where i am',
          'my location',
          'naan engae irukkiren',
          'நான் எங்கே இருக்கிறேன்',
          'nenu ekkada unnanu',
          'నేను ఎక్కడ ఉన్నాను',
          'naanu elliddene',
          'ನಾನು ಎಲ್ಲಿದ್ದೇನೆ'
        ],
      ),
      const VoiceAction(
        id: 'refresh_location',
        label: 'Refresh Location',
        screenContext: 'global',
        aliases: ['refresh location', 'refresh current location', 'refresh location screen'],
      ),
      const VoiceAction(
        id: 'search_google_maps',
        label: 'Search Google Maps',
        screenContext: 'global',
        aliases: ['search places on google maps', 'search google maps', 'google maps', 'open google maps'],
      ),
    ]);
  }

  /// Helper method to identify ambient noise, filler words, or empty speech fragments
  bool isNoiseOrFiller(String rawText) {
    final clean = rawText.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().trim();
    if (clean.isEmpty) return true;

    // Direct action match is never treated as noise
    final resolvedMatch = _actionRegistry.resolveAction(
      rawTranscript: rawText,
      currentScreenContext: _currentScreenContext,
    );
    if (resolvedMatch != null) return false;

    // Allow explicit language switch commands even if short
    if (LanguageCommandParser.parseTargetLanguage(clean) != null) return false;

    // Common ambient noise / filler words
    final fillerWords = {
      'uh', 'um', 'mm', 'ah', 'ha', 'oh', 'er', 'hmm', 'huh', 'okay', 'ok',
      'a', 'an', 'the', 'is', 'it', 'or', 'in', 'on', 'at', 'by', 'hi', 'hey',
    };

    if (fillerWords.contains(clean)) return true;

    // Any raw string <= 2 characters that isn't a direct command is treated as noise
    if (clean.length <= 2) return true;

    return false;
  }

  Timer? _guardedRecoveryTimer;
  int _recoveryGeneration = 0;
  bool _isRestartPending = false;

  void _scheduleGuardedRecovery({int delayMs = 400}) {
    final int gen = ++_recoveryGeneration;
    _guardedRecoveryTimer?.cancel();
    if (!_isAutoVoiceEnabled || _isYieldedToFeature || _ttsService.isSpeaking) {
      return;
    }
    _guardedRecoveryTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (gen != _recoveryGeneration) {
        return;
      }
      _guardedRecoveryTimer = null;
      _isExecutingCommand = false;
      final ctx = _safeGlobalContext ?? _activeContext;
      if (ctx != null && ctx.mounted && _isAutoVoiceEnabled && !_isYieldedToFeature && !_sttService.isListening) {
        debugPrint('[VOICE_RECOVERY] Triggering guarded self-healing STT restart (gen $gen)');
        await triggerAutoListening(ctx);
      }
    });
  }

  int _activeSttSessionId = 0;
  int _processedSttSessionId = -1;

  /// Start Automatic Voice Listening Session (No button press required)
  Future<void> triggerAutoListening(BuildContext context, {bool allowWhileSpeaking = false}) async {
    _guardedRecoveryTimer?.cancel();
    _guardedRecoveryTimer = null;
    _recoveryGeneration++;
    _activeContext = context;
    _activeSttSessionId++;
    final int currentSessionId = _activeSttSessionId;

    // Resync provider state if actual STT service is no longer listening
    if (!_sttService.isListening && _state == GlobalVoiceState.listening) {
      debugPrint('[VOICE_RUNTIME] Resyncing stale provider state: listening -> idle');
      _setVoiceState(GlobalVoiceState.idle, reason: "Resyncing stale listening state");
    }

    if (_isRestartPending || _isExecutingCommand || _isYieldedToFeature || (_ttsService.isSpeaking && !allowWhileSpeaking) || (_state == GlobalVoiceState.listening && _sttService.isListening) || _state == GlobalVoiceState.processingCommand) {
      debugPrint('[VOICE_RUNTIME] triggerAutoListening ignored due to state: $_state, executing: $_isExecutingCommand, pending: $_isRestartPending, listening: ${_sttService.isListening}');
      return;
    }

    _isRestartPending = true;

    try {
      debugPrint('[VOICE_RUNTIME] auto-restart started (bargeInAllowed: $allowWhileSpeaking)');
      debugPrint('[VOICE_RUNTIME] STT initialize entered');
      final hasPermission = await _sttService.initialize();
      debugPrint('[VOICE_RUNTIME] STT initialize result = $hasPermission');
      debugPrint('[VOICE_RUNTIME] speech available = $hasPermission');

      String speechLocale = 'en-IN';
      if (context.mounted) {
        try {
          speechLocale = Provider.of<AccessibilityProvider>(context, listen: false).speechLocale;
        } catch (_) {}
      }

      if (!hasPermission) {
        _isAutoVoiceEnabled = false;
        _setVoiceState(GlobalVoiceState.error, reason: "No STT permission");
        await speakConfirmation(VoiceResponseLocalizer.micPermissionRequired(speechLocale));
        return;
      }

      if (!allowWhileSpeaking) {
        await _sttService.stopListening();
        await Future.delayed(const Duration(milliseconds: 200));
        _setVoiceState(GlobalVoiceState.listening, reason: "Starting STT buffer");
      }
      _errorMessage = null;

      debugPrint('[VOICE_FINAL] STT listening');
      debugPrint('[VOICE_STARTUP] starting STT');
      debugPrint('[VOICE_RUNTIME] starting STT session with locale: $speechLocale (session $currentSessionId)...');

      await _sttService.startListening(
        localeId: speechLocale,
        onResult: (transcript, isFinal) async {
          _lastCommand = transcript;
          _displayTranscript = VoiceResponseLocalizer.formatRecognizedUserSpeech(transcript, speechLocale);
          debugPrint('[VOICE_TRANSCRIPT] display="$_displayTranscript"');
          debugPrint('[VOICE_STARTUP] speech result received (isFinal=$isFinal, session=$currentSessionId): $transcript');
          debugPrint('[VOICE_RUNTIME] recognized = $transcript');
          notifyListeners();

          // 2. FINAL SPEECH ONLY FOR COMMAND EXECUTION
          if (!isFinal) {
            // Interim result: updates live transcript UI only
            if (_ttsService.isSpeaking && transcript.trim().isNotEmpty) {
              final match = _actionRegistry.resolveAction(
                rawTranscript: transcript,
                currentScreenContext: _currentScreenContext,
              );
              if (match != null) {
                final actionId = match.action.id;
                debugPrint('[VOICE_BARGE_IN] transcript=$transcript');
                debugPrint('[VOICE_INTERRUPT] matchedAction=$actionId');
                await _ttsService.stop();
                debugPrint('[VOICE_INTERRUPT] ttsStopped=true');
              }
            }
            return;
          }

          // Final Result handling
          if (_ttsService.isSpeaking) {
            debugPrint('[VOICE_BARGE_IN] transcript=$transcript');
            final match = _actionRegistry.resolveAction(
              rawTranscript: transcript,
              currentScreenContext: _currentScreenContext,
            );
            if (match != null) {
              debugPrint('[VOICE_INTERRUPT] matchedAction=${match.action.id}');
            }
            await _ttsService.stop();
            debugPrint('[VOICE_INTERRUPT] ttsStopped=true');
          }

          if (_processedSttSessionId == currentSessionId) {
            debugPrint('[VOICE_DEDUPLICATION] Session $currentSessionId final result already processed via onResult, skipping duplicate execution');
            return;
          }
          _processedSttSessionId = currentSessionId;

          if (_activeContext != null && _activeContext!.mounted && !_isExecutingCommand) {
            await processVoiceCommand(_activeContext!, transcript);
          }
        },
        onComplete: () async {
          final recognizedWords = _sttService.lastWords.trim();
          debugPrint('[VOICE_FINAL] final transcript = "$recognizedWords"');
          debugPrint('[VOICE_RUNTIME] status = done');
          debugPrint('[VOICE_RUNTIME] STT session $currentSessionId completed. Recognized words: "$recognizedWords"');

          if (_processedSttSessionId == currentSessionId) {
            debugPrint('[VOICE_DEDUPLICATION] Session $currentSessionId already processed via onResult, skipping duplicate execution in onComplete');
            if (_isAutoVoiceEnabled && !_isYieldedToFeature && !_isExecutingCommand && !_ttsService.isSpeaking) {
              _scheduleGuardedRecovery(delayMs: 350);
            }
            return;
          }

          if (recognizedWords.isEmpty || isNoiseOrFiller(recognizedWords)) {
            _consecutiveSilenceCount++;
            if (_ttsService.isSpeaking) {
              debugPrint('[VOICE_BARGE_IN] no_user_speech');
            }

            if (_state != GlobalVoiceState.speaking) {
              _setVoiceState(GlobalVoiceState.idle, reason: "Silence/Noise timeout reset");
            }

            if (_isAutoVoiceEnabled && !_isYieldedToFeature && !_isExecutingCommand) {
              final delayMs = _ttsService.isSpeaking ? 100 : 250;
              _scheduleGuardedRecovery(delayMs: delayMs);
            }
          } else {
            _processedSttSessionId = currentSessionId;
            _consecutiveSilenceCount = 0;
            if (_ttsService.isSpeaking) {
              final match = _actionRegistry.resolveAction(
                rawTranscript: recognizedWords,
                currentScreenContext: _currentScreenContext,
              );
              if (match != null) {
                final actionId = match.action.id;
                debugPrint('[VOICE_INTERRUPT] matchedAction=$actionId');
                await _ttsService.stop();
                debugPrint('[VOICE_INTERRUPT] ttsStopped=true');
              }
            }
            if (_activeContext != null && _activeContext!.mounted && !_isExecutingCommand) {
              await processVoiceCommand(_activeContext!, recognizedWords);
            }
          }
        },
      );
    } finally {
      _isRestartPending = false;
    }
  }

  /// Manual trigger for Voice Control FAB fallback
  Future<void> startManualSession(BuildContext context) async {
    _consecutiveSilenceCount = 0;
    _isAutoVoiceEnabled = true;
    _isYieldedToFeature = false;
    _setVoiceState(GlobalVoiceState.idle, reason: "Manual FAB pressed");
    await triggerAutoListening(context);
  }

  /// Stop current voice session & speech output
  Future<void> stopSession() async {
    await _sttService.stopListening();
    await _ttsService.stop();
    _isExecutingCommand = false;
    _setVoiceState(GlobalVoiceState.stopped, reason: "Session stopped");
  }

  /// Wait for route transition settlement and safely resume Global Voice STT if not already active
  Future<void> _waitForRouteSettledAndResumeVoice() async {
    _isExecutingCommand = false;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
    });
    await completer.future;

    debugPrint('[VOICE_FLOW] route settled');

    if (!_ttsService.isSpeaking && _state != GlobalVoiceState.speaking) {
      _setVoiceState(GlobalVoiceState.idle, reason: "Route settled post-navigation");
      if (_isAutoVoiceEnabled && !_isYieldedToFeature && !_sttService.isListening) {
        debugPrint('[VOICE_FINAL] STT resumed');
        debugPrint('[VOICE_FLOW] global voice resuming');
        final targetContext = _safeGlobalContext ?? _activeContext;
        if (targetContext != null && targetContext.mounted) {
          await triggerAutoListening(targetContext);
        }
      }
    } else {
      debugPrint('[VOICE_FLOW] Route settled while confirmation TTS speaking; STT will resume upon playback finish');
    }
  }

  /// Automatically adapt language state if command contains clear regional language markers
  void _adaptLanguageFromCommand(BuildContext context, String clean) {
    String? detectedCode;
    // Telugu markers
    if (clean.contains('cheyyi') || clean.contains('ki vellu') || clean.contains('ki po') || clean.contains('ki marchu') || clean.contains('anuvadam') || clean.contains('vinadam')) {
      detectedCode = 'te';
    }
    // Tamil markers
    else if (clean.contains('pannu') || clean.contains('ku po') || clean.contains('ku thirumbu') || clean.contains('pinnaal po') || clean.contains('ku maathu')) {
      detectedCode = 'ta';
    }
    // Kannada markers
    else if (clean.contains('maadi') || clean.contains('ge hogi') || clean.contains('ge thirugi') || clean.contains('hinde hogi') || clean.contains('ge badalisi')) {
      detectedCode = 'kn';
    }
    // Hindi markers
    else if (clean.contains('kholo') || clean.contains('pe chalo') || clean.contains('wapas jao') || clean.contains('piche jao') || clean.contains('mein change') || clean.contains('badlo')) {
      detectedCode = 'hi';
    }

    if (detectedCode != null && context.mounted) {
      debugPrint('[VOICE_FINAL] detected language = $detectedCode');
      debugPrint('[VOICE_DEVICE] detected language = $detectedCode');
      try {
        final accProvider = Provider.of<AccessibilityProvider>(context, listen: false);
        if (accProvider.appLanguage != detectedCode) {
          debugPrint('[VOICE_LANG] Auto adapting language state: ${accProvider.appLanguage} -> $detectedCode');
          accProvider.setAppLanguage(detectedCode);
        }
      } catch (e) {
        debugPrint('[VOICE_LANG] Error adapting language: $e');
      }
    }
  }

  Future<void> _executeNavigation(
    BuildContext? context, {
    required String matchedCommand,
    required String routeName,
    required String ttsMessage,
    bool removeUntil = false,
  }) async {
    debugPrint('[VOICE_NAV] target=$routeName');
    debugPrint('[VOICE_FINAL] matched command = $matchedCommand');
    debugPrint('[VOICE_FLOW] command recognized: $matchedCommand');
    debugPrint('[VOICE_NAV_DEBUG] matched command = $matchedCommand');
    debugPrint('[VOICE_NAV_DEBUG] route = $routeName');

    String locale = 'en-IN';
    final targetCtx = (_activeContext != null && _activeContext!.mounted) ? _activeContext! : (context != null && context.mounted ? context : null);
    if (targetCtx != null) {
      try {
        locale = Provider.of<AccessibilityProvider>(targetCtx, listen: false).speechLocale;
      } catch (_) {}
    }
    debugPrint('[VOICE_FINAL] response language = $locale');
    final localizedMessage = ttsMessage.trim().isNotEmpty
        ? ttsMessage.trim()
        : VoiceResponseLocalizer.openingRoute(matchedCommand, locale);

    await speakConfirmation(localizedMessage);

    debugPrint('[VOICE_NAV_DEBUG] Navigator call started for route: $routeName');
    final navState = AppRoutes.navigatorKey.currentState;
    if (navState != null) {
      if (removeUntil) {
        navState.pushNamedAndRemoveUntil(routeName, (route) => false);
      } else {
        navState.pushNamed(routeName);
      }
      debugPrint('[VOICE_NAV_DEBUG] Navigator call completed via navigatorKey for route: $routeName');
    } else if (targetCtx != null && targetCtx.mounted) {
      debugPrint('[VOICE_NAV_DEBUG] navigatorKey.currentState was null, falling back to Navigator.of(targetCtx)');
      if (removeUntil) {
        Navigator.of(targetCtx).pushNamedAndRemoveUntil(routeName, (route) => false);
      } else {
        Navigator.of(targetCtx).pushNamed(routeName);
      }
      debugPrint('[VOICE_NAV_DEBUG] Navigator call completed via Navigator.of(targetCtx) fallback');
    } else {
      debugPrint('[VOICE_NAV_DEBUG] Navigation failed: navigatorKey.currentState is null and targetCtx not mounted');
    }

    debugPrint('[VOICE_FLOW] navigation executed');

    await _waitForRouteSettledAndResumeVoice();
  }

  Future<void> _executePop(BuildContext? context) async {
    debugPrint('[VOICE_NAV] target=pop');
    debugPrint('[VOICE_FLOW] command recognized: go_back');
    debugPrint('[VOICE_NAV_DEBUG] matched command = go_back');
    debugPrint('[VOICE_NAV_DEBUG] route = pop');

    String locale = 'en-IN';
    final targetCtx = (_activeContext != null && _activeContext!.mounted) ? _activeContext! : (context != null && context.mounted ? context : null);
    if (targetCtx != null) {
      try {
        locale = Provider.of<AccessibilityProvider>(targetCtx, listen: false).speechLocale;
      } catch (_) {}
    }
    await speakConfirmation(VoiceResponseLocalizer.openingRoute('going_back', locale));

    debugPrint('[VOICE_NAV_DEBUG] Navigator call started for pop');
    final navState = AppRoutes.navigatorKey.currentState;
    if (navState != null && navState.canPop()) {
      navState.pop();
      debugPrint('[VOICE_NAV_DEBUG] Navigator call completed via navigatorKey pop');
    } else if (targetCtx != null && targetCtx.mounted && Navigator.of(targetCtx).canPop()) {
      Navigator.of(targetCtx).pop();
      debugPrint('[VOICE_NAV_DEBUG] Navigator call completed via Navigator.of(targetCtx) pop');
    } else if (navState != null) {
      debugPrint('[VOICE_NAV_DEBUG] canPop was false, returning to Home Dashboard as graceful fallback');
      navState.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } else {
      debugPrint('[VOICE_NAV_DEBUG] Navigation pop ignored (cannot pop)');
    }

    debugPrint('[VOICE_FLOW] navigation executed');

    await _waitForRouteSettledAndResumeVoice();
  }

  /// Process recognized voice command using normalized matching & route navigation
  Future<void> processVoiceCommand(BuildContext context, String rawCommand) async {
    if (_isYieldedToFeature || _isExecutingCommand) {
      debugPrint('[VOICE_RUNTIME] Aborting processVoiceCommand: yielded=$_isYieldedToFeature, executing=$_isExecutingCommand');
      return;
    }

    _isExecutingCommand = true;
    debugPrint('[VOICE_STARTUP] command processing: $rawCommand');
    debugPrint('[VOICE_NAV_DEBUG] raw recognized = "$rawCommand"');
    debugPrint('[VOICE_RUNTIME] command lock acquired');
    debugPrint('[VOICE_RUNTIME] command parser entered');
    _setVoiceState(GlobalVoiceState.processingCommand, reason: "Processing: $rawCommand");

    try {
      final String clean = rawCommand.replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      debugPrint('[VOICE_NORMALIZED] text="$clean"');
      debugPrint('[VOICE_NAV_DEBUG] normalized = "$clean"');

      final bool isNoise = isNoiseOrFiller(rawCommand);
      debugPrint('[VOICE_FILTER] text="$clean" result=${isNoise ? "REJECT" : "ACCEPT"}');

      if (isNoise) {
        _isExecutingCommand = false;
        _setVoiceState(GlobalVoiceState.idle, reason: "Noise rejected");
        return;
      }

      // ==================== SOS STATE MACHINE INTERCEPT ====================
      // When state == confirmingDanger or waitingForCodeWord, DO NOT send transcript to normal Global Voice actions!
      try {
        final sosProvider = Provider.of<EmergencySosProvider>(context, listen: false);
        if (sosProvider.state == SosStateEnum.confirmingDanger) {
          debugPrint('[SOS_INTERCEPT] Intercepting speech during confirmingDanger: "$clean"');
          // ACCEPT: "yes", "yes i am", "i am in danger", "help me", "confirm"
          if (clean == 'yes' || clean.contains('yes i am') || clean.contains('in danger') || clean.contains('help me') || clean == 'confirm') {
            _isExecutingCommand = false;
            _setVoiceState(GlobalVoiceState.idle, reason: "SOS confirmed by voice");
            sosProvider.promptForCodeWord();
            return;
          } else if (clean == 'no' || clean == 'cancel' || clean == 'stop') {
            _isExecutingCommand = false;
            _setVoiceState(GlobalVoiceState.idle, reason: "SOS cancelled by voice");
            await sosProvider.cancelSos();
            return;
          }
          // Ignore other speech while confirming danger
          _isExecutingCommand = false;
          _setVoiceState(GlobalVoiceState.idle, reason: "Speech during confirmingDanger ignored");
          return;
        }

        if (sosProvider.state == SosStateEnum.waitingForCodeWord) {
          debugPrint('[SOS_INTERCEPT] Intercepting code word speech during waitingForCodeWord');
          _isExecutingCommand = false;
          _setVoiceState(GlobalVoiceState.idle, reason: "SOS code word processed");
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final userId = authProvider.user?.userId ?? '';
          await sosProvider.verifyCodeWordAndSend(rawCommand, userId);
          return;
        }
      } catch (e) {
        debugPrint('[SOS_INTERCEPT] EmergencySosProvider check error: $e');
      }

      // TTS Echo Guard: Filter out STT results that mirror active OR reverberating TTS output
      final bool isActivelySpeaking = _ttsService.isSpeaking || _state == GlobalVoiceState.speaking;
      final bool isTtsAcousticWindow = _lastTtsFinishedTime != null &&
          DateTime.now().difference(_lastTtsFinishedTime!) < const Duration(milliseconds: 350);

      if (isActivelySpeaking || isTtsAcousticWindow) {
        final String activeOrRecentTts = isActivelySpeaking ? _lastTtsOutput : _recentTtsOutput;
        if (activeOrRecentTts.trim().isNotEmpty) {
          final cleanTts = activeOrRecentTts
              .replaceAll(RegExp(r'[\.,!?:;\-_()\[\]{}"\x27]'), '')
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          final cleanTtsLine1 = cleanTts.contains('\n')
              ? cleanTts.split('\n').first.trim()
              : cleanTts;

          final bool isInterrupt = clean == 'stop' || clean == 'cancel' || clean == 'quiet' || clean == 'hush';

          if (isActivelySpeaking && !isInterrupt) {
            debugPrint('[VOICE_ECHO_GUARD] Ignoring STT transcript while TTS actively speaks: "$clean"');
            _isExecutingCommand = false;
            if (_state != GlobalVoiceState.listening) {
              _setVoiceState(GlobalVoiceState.idle, reason: "TTS active, input ignored");
            }
            return;
          }

          if (!isActivelySpeaking && isTtsAcousticWindow && !isInterrupt) {
            final bool isVerbatimEcho = clean == cleanTts || clean == cleanTtsLine1 ||
                (cleanTtsLine1.length >= 10 && clean.contains(cleanTtsLine1));
            // Check if user spoke a recognized action intent
            final candidate = _actionRegistry.resolveAction(
              rawTranscript: rawCommand,
              currentScreenContext: _currentScreenContext,
            );
            if (isVerbatimEcho && candidate == null) {
              debugPrint('[VOICE_ECHO_GUARD] Ignoring STT transcript matching recent TTS output: "$clean"');
              _isExecutingCommand = false;
              if (_state != GlobalVoiceState.listening) {
                _setVoiceState(GlobalVoiceState.idle, reason: "TTS echo ignored");
              }
              return;
            }
          }
        }
      }

      // Deduplication Guard: Ignore identical final command within 1.8s window
      final now = DateTime.now();
      if (_lastExecutedCommand == clean && _lastExecutedTime != null && now.difference(_lastExecutedTime!) < const Duration(milliseconds: 1800)) {
        debugPrint('[VOICE_DEDUPLICATION] Ignoring duplicate final command "$clean" within 1.8s window');
        _isExecutingCommand = false;
        if (_state != GlobalVoiceState.listening) {
          _setVoiceState(GlobalVoiceState.idle, reason: "Duplicate command ignored");
        }
        return;
      }

      debugPrint('[VOICE_LANG] raw transcript = $rawCommand');
      debugPrint('[VOICE_LANG] normalized transcript = $clean');

      // 0. PRIORITY VOICE COMMAND TO CHANGE LANGUAGE (From ANY screen including Login)
      final parsedTargetLang = LanguageCommandParser.parseTargetLanguage(rawCommand);
      debugPrint('[VOICE_LANG] target language = ${parsedTargetLang ?? "none"}');

      if (parsedTargetLang != null) {
        if (parsedTargetLang == _currentLanguageCode) {
          debugPrint('[VOICE_LANG] Target language $parsedTargetLang is already active language.');
          _isExecutingCommand = false;
          if (_state != GlobalVoiceState.listening) {
            _setVoiceState(GlobalVoiceState.idle, reason: "Target language already active");
          }
          final bool isRecentFeedback = _lastTtsFinishedTime != null &&
              DateTime.now().difference(_lastTtsFinishedTime!) < const Duration(milliseconds: 4000) &&
              (_recentTtsOutput.contains('already active') ||
               _recentTtsOutput.contains('ప్రస్తుతం') ||
               _recentTtsOutput.contains('ஏற்கனவே') ||
               _recentTtsOutput.contains('ಈಗಾಗಲೇ') ||
               _recentTtsOutput.contains('पहले से'));

          if (!isRecentFeedback) {
            final locale = VoiceResponseLocalizer.normalizeLocale(parsedTargetLang);
            final msg = VoiceResponseLocalizer.languageAlreadyActive(locale);
            await speakConfirmation(msg);
          }
          return;
        }

        // Enforce a 1.5s post-language-switch safety cooldown to prevent double execution from same utterance
        if (_lastLanguageSwitchTime != null && now.difference(_lastLanguageSwitchTime!) < const Duration(milliseconds: 1500)) {
          debugPrint('[VOICE_LANG_COOLDOWN] Ignoring duplicate language switch attempt within 1.5s window: "$clean"');
          _isExecutingCommand = false;
          if (_state != GlobalVoiceState.listening) {
            _setVoiceState(GlobalVoiceState.idle, reason: "Language switch cooldown active");
          }
          return;
        }

        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_MATCH] action=change_language');
        debugPrint('[VOICE_EXECUTE] action=change_language');
        debugPrint('[VOICE_ACTION] actionId=change_language status=EXECUTED');
        _currentLanguageCode = parsedTargetLang;
        _lastLanguageSwitchTime = now;

        try {
          if (context.mounted) {
            final accProvider = Provider.of<AccessibilityProvider>(context, listen: false);
            await accProvider.setAppLanguage(parsedTargetLang);
            final newLocale = accProvider.speechLocale;

            // Stop current STT session and cancel pending recovery timers before speaking confirmation
            _guardedRecoveryTimer?.cancel();
            _guardedRecoveryTimer = null;
            await _sttService.stopListening();
            await _ttsService.setLanguage(newLocale);

            final confirmationMsg = VoiceResponseLocalizer.languageChangedConfirmation(newLocale);
            _recentTtsOutput = confirmationMsg;
            _lastTtsOutput = confirmationMsg;

            await speakConfirmation(confirmationMsg);
          }
          debugPrint('[VOICE_EXECUTE] action=change_language result=SUCCESS');
        } catch (e) {
          debugPrint('[VOICE_EXECUTE] action=change_language result=FAILURE');
        } finally {
          _isExecutingCommand = false;
        }
        return;
      }

      // Automatically adapt language state if regional speech markers are detected
      _adaptLanguageFromCommand(context, clean);

      // ==================== DYNAMIC COGNITIVE & TASK COMMANDS ====================
      // 1. ADD TASK ("add task <title>", "create a task <title>", "add <title> to my tasks")
      if (clean.startsWith('add task ') ||
          clean.startsWith('add a task ') ||
          clean.startsWith('create task ') ||
          clean.startsWith('create a task ') ||
          (clean.startsWith('add ') && (clean.contains(' to my tasks') || clean.contains(' to tasks')))) {
        String title = '';
        if (clean.startsWith('add task ')) {
          title = clean.substring(9).trim();
        } else if (clean.startsWith('add a task ')) {
          title = clean.substring(11).trim();
        } else if (clean.startsWith('create task ')) {
          title = clean.substring(12).trim();
        } else if (clean.startsWith('create a task ')) {
          title = clean.substring(14).trim();
        } else if (clean.startsWith('add ')) {
          title = clean.substring(4).replaceAll('to my tasks', '').replaceAll('to tasks', '').trim();
        }

        if (title.isNotEmpty) {
          final formattedTitle = title[0].toUpperCase() + title.substring(1);
          _displayTranscript = 'Adding task: "$formattedTitle"...';
          notifyListeners();
          if (context.mounted) {
            try {
              final todoProvider = Provider.of<TodoProvider>(context, listen: false);
              await todoProvider.addTask(formattedTitle);
              await speakConfirmation('Added task: $formattedTitle.');
            } catch (e) {
              await speakConfirmation('Failed to add task.');
            }
          }
          return;
        }
      }

      // 2. COMPLETE TASK ("complete <title>", "mark <title> complete", "complete my <title> task")
      if (clean.startsWith('complete task ') ||
          clean.startsWith('complete my ') ||
          clean.startsWith('complete ') ||
          (clean.startsWith('mark ') && (clean.contains(' complete') || clean.contains(' completed')))) {
        String query = '';
        if (clean.startsWith('complete task ')) {
          query = clean.substring(14).replaceAll('task', '').trim();
        } else if (clean.startsWith('complete my ')) {
          query = clean.substring(12).replaceAll('task', '').trim();
        } else if (clean.startsWith('complete ')) {
          query = clean.substring(9).replaceAll('task', '').trim();
        } else if (clean.startsWith('mark ')) {
          query = clean.substring(5).replaceAll('completed', '').replaceAll('complete', '').replaceAll('task', '').trim();
        }

        if (query.isNotEmpty && context.mounted) {
          _displayTranscript = 'Completing task: "$query"...';
          notifyListeners();
          try {
            final todoProvider = Provider.of<TodoProvider>(context, listen: false);
            final matched = await todoProvider.completeTaskByTitle(query);
            if (matched != null) {
              await speakConfirmation('Marked task completed: ${matched.title}.');
            } else {
              await speakConfirmation("I couldn't find that task.");
            }
          } catch (_) {
            await speakConfirmation("I couldn't find that task.");
          }
          return;
        }
      }

      // 3. ISL SIGN LANGUAGE PHRASE INTERCEPT
      // Intercept sign phrase if on the Sign Language screen OR if user explicitly says "sign <phrase>"
      final bool isExplicitSignRequest = clean.startsWith('sign ') ||
          clean.startsWith('show sign ') ||
          clean.startsWith('demonstrate sign ') ||
          clean.startsWith('how to sign ');
      final bool isOnSignScreen = _currentScreenContext.contains('sign');

      if ((isOnSignScreen || isExplicitSignRequest) && context.mounted) {
        String signQuery = clean;
        if (clean.startsWith('sign ')) {
          signQuery = clean.substring(5).trim();
        } else if (clean.startsWith('show sign for ')) {
          signQuery = clean.substring(14).trim();
        } else if (clean.startsWith('show sign ')) {
          signQuery = clean.substring(10).trim();
        } else if (clean.startsWith('demonstrate sign for ')) {
          signQuery = clean.substring(21).trim();
        } else if (clean.startsWith('demonstrate sign ')) {
          signQuery = clean.substring(17).trim();
        } else if (clean.startsWith('how to sign ')) {
          signQuery = clean.substring(12).trim();
        }

        // Do not intercept if query is a global navigation command (e.g. "home", "go home", "back", "go back")
        final bool isNavCommand = signQuery == 'home' || signQuery == 'go home' || signQuery == 'back' || signQuery == 'go back';
        if (!isNavCommand) {
          final islMatchedPhrase = SignLanguagePhraseRegistry.findPhrase(signQuery);
          if (islMatchedPhrase != null) {
            try {
              final signProvider = Provider.of<SignLanguageProvider>(context, listen: false);
              _consecutiveUnrecognizedCount = 0;
              await speakConfirmation('Demonstrating sign for ${islMatchedPhrase.displayText}.');
              await signProvider.selectAndPlayPhrase(islMatchedPhrase);
              return;
            } catch (_) {
              if (isExplicitSignRequest) {
                _consecutiveUnrecognizedCount = 0;
                await _executeNavigation(
                  context,
                  matchedCommand: 'sign_language',
                  routeName: AppRoutes.signLanguage,
                  ttsMessage: 'Opening Sign Language for ${islMatchedPhrase.displayText}.',
                );
                return;
              }
            }
          }
        }
      }

      // 4. DELETE TASK ("delete <title>", "delete the <title> task", "remove task <title>")
      if (clean.startsWith('delete task ') ||
          clean.startsWith('delete the ') ||
          clean.startsWith('delete ') ||
          clean.startsWith('remove task ') ||
          clean.startsWith('remove ')) {
        String query = '';
        if (clean.startsWith('delete task ')) {
          query = clean.substring(12).replaceAll('task', '').trim();
        } else if (clean.startsWith('delete the ')) {
          query = clean.substring(11).replaceAll('task', '').trim();
        } else if (clean.startsWith('delete ')) {
          query = clean.substring(7).replaceAll('task', '').trim();
        } else if (clean.startsWith('remove task ')) {
          query = clean.substring(12).replaceAll('task', '').trim();
        } else if (clean.startsWith('remove ')) {
          query = clean.substring(7).replaceAll('task', '').trim();
        }

        if (query.isNotEmpty && context.mounted) {
          _displayTranscript = 'Deleting task: "$query"...';
          notifyListeners();
          try {
            final todoProvider = Provider.of<TodoProvider>(context, listen: false);
            final matched = await todoProvider.deleteTaskByTitle(query);
            if (matched != null) {
              await speakConfirmation('Deleted task: ${matched.title}.');
            } else {
              await speakConfirmation("I couldn't find that task.");
            }
          } catch (_) {
            await speakConfirmation("I couldn't find that task.");
          }
          return;
        }
      }



      // In-Screen Vision Commands (Capture, Repeat, Stop)
      if (_currentScreenContext.contains('vision') || _currentScreenContext.contains('blind')) {
        if (clean == 'capture' || clean == 'take picture' || clean == 'scan' || clean == 'read now' || clean == 'describe now') {
          _isExecutingCommand = false;
          _setVoiceState(GlobalVoiceState.idle);
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.captureAndProcess();
          } catch (_) {}
          return;
        }
        if (clean == 'repeat' || clean == 'repeat text' || clean == 'read again' || clean == 'repeat description') {
          _isExecutingCommand = false;
          _setVoiceState(GlobalVoiceState.idle);
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            final res = visionProvider.lastResult;
            if (res != null && res.text.isNotEmpty) {
              await speakConfirmation(res.text);
            } else {
              await speakConfirmation('No previous result to repeat.');
            }
          } catch (_) {}
          return;
        }
      }

      // Voice Read Tasks Command
      if (clean == 'what are my tasks' || clean == 'read my tasks' || clean == 'read tasks' || clean == 'tell my tasks' || clean == 'my tasks') {
        _isExecutingCommand = false;
        _setVoiceState(GlobalVoiceState.idle);
        try {
          final todoProvider = Provider.of<TodoProvider>(context, listen: false);
          final active = todoProvider.upcomingTasks;
          if (active.isEmpty) {
            await speakConfirmation('You have no pending tasks. Great job!');
          } else {
            final taskList = active.map((t) => t.title).join(', ');
            await speakConfirmation('You have ${active.length} pending tasks: $taskList.');
          }
        } catch (_) {}
        return;
      }

      // 0B. RESOLVE ACTION VIA CENTRALIZED VOICE ACTION REGISTRY
      debugPrint('[VOICE_RESOLVE] screen="$_currentScreenContext" text="$clean"');
      final match = _actionRegistry.resolveAction(
        rawTranscript: rawCommand,
        currentScreenContext: _currentScreenContext,
      );

      final String matchedActionId = match != null ? match.action.id : "NONE";
      debugPrint('[VOICE_MATCH] action=$matchedActionId');

      if (match != null) {
        _lastExecutedCommand = clean;
        _lastExecutedTime = now;
        _consecutiveUnrecognizedCount = 0;
        final actionId = match.action.id;
        debugPrint('[VOICE_EXECUTE] action=$actionId');
        debugPrint('[VOICE_ACTION] actionId=$actionId status=EXECUTED');

        switch (actionId) {
          case 'start_reading':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.startReadingDocument();
              } catch (_) {}
            }
            return;

          case 'pause_reading':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.pauseReadingDocument();
              } catch (_) {}
            }
            return;

          case 'resume_reading':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.resumeReadingDocument();
              } catch (_) {}
            }
            return;

          case 'stop_reading':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.stopReadingDocument();
              } catch (_) {}
            }
            return;

          case 'next_page':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.nextPage();
              } catch (_) {}
            }
            return;

          case 'previous_page':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.previousPage();
              } catch (_) {}
            }
            return;

          case 'story_summary':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.summarizeActiveDocument();
              } catch (_) {}
            }
            return;

          case 'import_document':
            if (context.mounted) {
              try {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.setVisionMode(VisionMode.readText);
                await visionProvider.importDocument();
              } catch (_) {}
            }
            return;

          case 'open_visual_assistance':
          case 'visual_assistance':
            await _executeNavigation(
              context,
              matchedCommand: 'visual_assistance',
              routeName: AppRoutes.vision,
              ttsMessage: 'Opening Visual Assistance.',
            );
            return;

          case 'blind_mode':
            await _executeNavigation(
              context,
              matchedCommand: 'blind_mode',
              routeName: AppRoutes.blindMode,
              ttsMessage: 'Opening Blind Assistance Dashboard.',
            );
            return;

          case 'start_object_detection':
            try {
              final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
              await visionProvider.setVisionMode(VisionMode.identifyObject);
              await visionProvider.startContinuousMonitoring();
            } catch (_) {}
            if (_currentScreenContext != 'vision') {
              if (context.mounted) {
                await _executeNavigation(
                  context,
                  matchedCommand: 'start_object_detection',
                  routeName: AppRoutes.vision,
                  ttsMessage: 'Starting Object Detection.',
                );
              }
            } else {
              await speakConfirmation('Object detection started.');
            }
            return;

          case 'stop_object_detection':
            try {
              final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
              await visionProvider.stopContinuousMonitoring();
            } catch (_) {}
            await speakConfirmation('Object detection stopped.');
            return;

          case 'repeat_speech':
            try {
              if (_currentScreenContext == 'vision' && context.mounted) {
                final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
                await visionProvider.speakResult();
                return;
              }
            } catch (_) {}
            if (_recentTtsOutput.isNotEmpty) {
              await speakConfirmation(_recentTtsOutput);
            }
            return;

          case 'open_hearing_assistance':
          case 'hearing_assistance':
          case 'deaf_mode':
            await _executeNavigation(
              context,
              matchedCommand: 'hearing_assistance',
              routeName: AppRoutes.hearingAssistance,
              ttsMessage: 'Opening Hearing Assistance Dashboard.',
            );
            return;

          case 'open_cognitive_assistance':
          case 'cognitive_assistance':
            await _executeNavigation(
              context,
              matchedCommand: 'cognitive_assistance',
              routeName: AppRoutes.cognitiveAssistance,
              ttsMessage: 'Opening Cognitive Assistance Dashboard.',
            );
            return;

          case 'open_physical_assistance':
          case 'physical_assistance':
            await _executeNavigation(
              context,
              matchedCommand: 'physical_assistance',
              routeName: AppRoutes.physicalAssistance,
              ttsMessage: 'Opening Physical Assistance Dashboard.',
            );
            return;

          case 'open_normal_user':
          case 'normal_user':
            await _executeNavigation(
              context,
              matchedCommand: 'normal_user',
              routeName: AppRoutes.normalUser,
              ttsMessage: 'Opening Normal User Suite.',
            );
            return;

          case 'open_sign_language':
          case 'sign_language':
            await _executeNavigation(
              context,
              matchedCommand: 'sign_language',
              routeName: AppRoutes.signLanguage,
              ttsMessage: 'Opening Sign Language Home.',
            );
            return;

          case 'open_sign_to_text':
          case 'sign_to_text':
            await _executeNavigation(
              context,
              matchedCommand: 'sign_to_text',
              routeName: AppRoutes.signToText,
              ttsMessage: 'Opening Sign Language to Text.',
            );
            return;

          case 'open_text_to_sign':
          case 'text_to_sign':
            await _executeNavigation(
              context,
              matchedCommand: 'text_to_sign',
              routeName: AppRoutes.textToSign,
              ttsMessage: 'Opening Text to Sign Language.',
            );
            return;

          case 'object_detection':
            try {
              final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
              await visionProvider.setVisionMode(VisionMode.identifyObject);
            } catch (_) {}
            if (context.mounted) {
              await _executeNavigation(
                context,
                matchedCommand: 'object_detection',
                routeName: AppRoutes.vision,
                ttsMessage: 'Opening Object Detection.',
              );
            }
            return;

          case 'ocr':
            try {
              final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
              await visionProvider.setVisionMode(VisionMode.readText);
            } catch (_) {}
            if (context.mounted) {
              await _executeNavigation(
                context,
                matchedCommand: 'ocr',
                routeName: AppRoutes.vision,
                ttsMessage: 'Opening OCR Text Reader.',
              );
            }
            return;

          case 'scene_description':
            try {
              final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
              await visionProvider.setVisionMode(VisionMode.describeScene);
            } catch (_) {}
            if (context.mounted) {
              await _executeNavigation(
                context,
                matchedCommand: 'scene_description',
                routeName: AppRoutes.vision,
                ttsMessage: 'Opening Scene Description.',
              );
            }
            return;

          case 'document_reader':
          case 'open_document_reader':
            try {
              final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
              await visionProvider.setVisionMode(VisionMode.readText);
            } catch (_) {}
            if (context.mounted) {
              await _executeNavigation(
                context,
                matchedCommand: 'document_reader',
                routeName: AppRoutes.vision,
                ttsMessage: 'Opening Document Reader.',
              );
            }
            return;

          case 'open_tasks':
          case 'open_daily_tasks':
          case 'daily_tasks':
            await _executeNavigation(
              context,
              matchedCommand: 'daily_tasks',
              routeName: AppRoutes.todoList,
              ttsMessage: 'Opening Daily Tasks.',
            );
            return;

          case 'open_reminders':
          case 'reminders':
            await _executeNavigation(
              context,
              matchedCommand: 'reminders',
              routeName: AppRoutes.reminders,
              ttsMessage: 'Opening Reminders and Medication.',
            );
            return;

          case 'open_notes':
          case 'notes':
            await _executeNavigation(
              context,
              matchedCommand: 'notes',
              routeName: AppRoutes.notes,
              ttsMessage: 'Opening Notes and Memory.',
            );
            return;

          case 'open_location':
          case 'location':
          case 'where_am_i':
            debugPrint('[LOCATION_TRACE] command received');
            debugPrint('[VOICE_NAV] ${AppRoutes.location}');
            String locationSpeech = VoiceResponseLocalizer.formatLocationResponse(_currentLanguageCode, '');
            final targetCtx = (_activeContext != null && _activeContext!.mounted) ? _activeContext! : (context.mounted ? context : null);
            if (targetCtx != null) {
              try {
                final physProvider = Provider.of<PhysicalAssistanceProvider>(targetCtx, listen: false);
                await physProvider.fetchCurrentLocation(requestPermissionIfDenied: true);
                if (physProvider.locationError != null && physProvider.currentAddress.isEmpty) {
                  locationSpeech = physProvider.locationError!;
                } else if (physProvider.currentAddress.isNotEmpty) {
                  locationSpeech = VoiceResponseLocalizer.formatLocationResponse(
                    _currentLanguageCode,
                    physProvider.currentAddress,
                  );
                }
              } catch (e) {
                debugPrint('[LOCATION_TRACE] error $e');
              }
            }
            await _executeNavigation(
              context,
              matchedCommand: 'open_location',
              routeName: AppRoutes.location,
              ttsMessage: locationSpeech,
            );
            return;

          case 'refresh_location':
            if (context.mounted) {
              try {
                final physProvider = Provider.of<PhysicalAssistanceProvider>(context, listen: false);
                await physProvider.fetchCurrentLocation(requestPermissionIfDenied: true);
                final locationSpeech = VoiceResponseLocalizer.formatLocationResponse(
                  _currentLanguageCode,
                  physProvider.currentAddress,
                );
                await speakConfirmation(locationSpeech);
              } catch (e) {
                debugPrint('[LOCATION_TRACE] error $e');
              }
            }
            return;

          case 'call_caregiver':
            if (context.mounted) {
              try {
                final physProvider = Provider.of<PhysicalAssistanceProvider>(context, listen: false);
                await speakConfirmation('Calling caregiver ${physProvider.caregiverName}.');
                await physProvider.callCaregiver();
              } catch (_) {}
            }
            return;

          case 'open_calendar':
            final navState = AppRoutes.navigatorKey.currentState;
            if (navState != null) {
              await speakConfirmation('Opening Calendar view.');
              navState.pushNamed(AppRoutes.reminders, arguments: {'tab': 2});
            }
            return;

          case 'open_translator':
          case 'translator':
            await _executeNavigation(
              context,
              matchedCommand: 'translator',
              routeName: AppRoutes.translator,
              ttsMessage: 'Opening Speech Translator.',
            );
            return;

          case 'emergency_sos':
            await _executeNavigation(
              context,
              matchedCommand: 'emergency',
              routeName: AppRoutes.emergencySos,
              ttsMessage: 'Opening Emergency SOS.',
            );
            return;

          case 'go_home':
            debugPrint('[VOICE_RESOLVE] go_home');
            debugPrint('[VOICE_MATCH] AppRoutes.home');
            debugPrint('[VOICE_EXECUTE] go_home');
            debugPrint('[VOICE_NAV] /home');
            await _executeNavigation(
              context,
              matchedCommand: 'home',
              routeName: AppRoutes.home,
              ttsMessage: 'Returning to Home Dashboard.',
              removeUntil: true,
            );
            return;

          case 'go_back':
            await _executePop(context);
            return;

          case 'stop_voice':
            _isAutoVoiceEnabled = false;
            await stopSession();
            return;

          case 'help':
            await _handleHelpCommand();
            return;
        }
      }

      // Automatically adapt language state if regional speech markers are detected
      _adaptLanguageFromCommand(context, clean);

      // 1. AUTHENTICATION & GOOGLE SIGN-IN COMMANDS (STEP 1 PRIORITY)
      if (_isCommandMatch(clean, [
        'sign in with google',
        'google sign in',
        'continue with google',
        'google login',
        'sign in google',
        'google signin',
        'login with google',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_STARTUP] Google Sign-In command matched');
        debugPrint('[VOICE_DEVICE] command matched = google_sign_in');
        debugPrint('[VOICE_NAV_DEBUG] matched command = google_sign_in');
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await speakConfirmation("Signing in with Google.");
          await authProvider.signInWithGoogle();
          if (authProvider.isAuthenticated) {
            final navState = AppRoutes.navigatorKey.currentState;
            if (navState != null) {
              navState.pushReplacementNamed(AppRoutes.home);
            }
          }
        } catch (e) {
          debugPrint('[VOICE_AUTH] Google sign in error: $e');
        }
        return;
      }

      // 1B. NICKNAME PROMPT & PERSONALIZATION VOICE COMMANDS
      if (_isCommandMatch(clean, ['sign out', 'logout', 'log out', 'signout'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await speakConfirmation('Signing out.');
          await authProvider.logout();
          final navState = AppRoutes.navigatorKey.currentState;
          if (navState != null) {
            navState.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          }
          return;
        }
      }

      if (_isCommandMatch(clean, ['login', 'log in', 'sign in', 'साइन इन', 'ಸೈನ್ ಇನ್', 'லாகின்', 'సైన్ ఇన్'])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_DEVICE] command matched = login');
        if (_currentScreenContext.contains('sign in') || _currentScreenContext.contains('login')) {
          await speakConfirmation('Please enter your email and password, or say Sign in with Google.');
        } else {
          await _executeNavigation(
            context,
            matchedCommand: 'login',
            routeName: AppRoutes.login,
            ttsMessage: 'Opening Sign In screen.',
          );
        }
        debugPrint('[VOICE_RUNTIME] command executed = true');
        return;
      }

      if (_isCommandMatch(clean, ['sign up', 'signup', 'register', 'create account', 'साइन अप', 'ಸೈನ್ ಅಪ್', 'பதிவு', 'సైన్ అప్'])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_DEVICE] command matched = signup');
        await _executeNavigation(
          context,
          matchedCommand: 'signup',
          routeName: AppRoutes.signup,
          ttsMessage: 'Opening Sign Up screen.',
        );
        debugPrint('[VOICE_RUNTIME] command executed = true');
        return;
      }

      if (_isCommandMatch(clean, ['continue', 'next', 'skip', 'पुढे', 'ಮುಂದೆ', 'తర్వాత'])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_NAV_DEBUG] matched command = continue');
        debugPrint('[VOICE_DEVICE] command matched = continue');
        final navState = AppRoutes.navigatorKey.currentState;
        if (navState != null && navState.canPop()) {
          navState.pushNamed(AppRoutes.home);
        }
        return;
      }

      // 2. STOP / QUIET COMMAND
      if (clean == 'stop' || clean == 'cancel' || clean == 'quiet' || clean == 'hush' || clean == 'रोकें' || clean == 'ನಿಲ್ಲಿಸಿ' || clean == 'நிறுத்து' || clean == '<ctrl42>') {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_NAV_DEBUG] matched command = stop');
        debugPrint('[VOICE_DEVICE] command matched = stop');
        debugPrint('[VOICE_RUNTIME] command matched = stop');
        _isAutoVoiceEnabled = false;
        await stopSession();
        return;
      }

      // 5. VOICE-FIRST 5 PRIMARY MODE SELECTION COMMANDS
      if (_isCommandMatch(clean, [
        'open blind assistance',
        'blind assistance',
        'open visual assistance',
        'visual assistance',
        'visual mode',
        'blind mode',
        'vision mode',
        'drushti',
        'देखना',
        'ದೃಷ್ಟಿ',
        'visual assistance open cheyyi',
        'visual assistance open pannu',
        'visual assistance open maadi',
        'visual assistance kholo',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'visual_assistance',
          routeName: AppRoutes.blindMode,
          ttsMessage: 'Opening Blind Assistance Dashboard.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open hearing assistance',
        'hearing assistance',
        'open deaf assistance',
        'deaf assistance',
        'deaf mode',
        'hearing mode',
        'hearing helper',
        'open hearing helper',
        'सुनना',
        'ಶ್ರವಣ',
        'vinadam',
        'hearing assistance open cheyyi',
        'hearing assistance open pannu',
        'hearing assistance open maadi',
        'hearing assistance kholo',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'hearing_assistance',
          routeName: AppRoutes.hearingAssistance,
          ttsMessage: 'Opening Hearing Assistance Dashboard.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open cognitive assistance',
        'cognitive assistance',
        'open cognitive assistant',
        'cognitive assistant',
        'cognitiv assistance',
        'cognitive mode',
        'memory mode',
        'cognitive helper',
        'memory assistant',
        'open cognitive',
        'cognitive',
        'याददाश्त',
        'ಮರೆವು',
        'cognitive assistance open cheyyi',
        'cognitive assistance open pannu',
        'cognitive assistance open maadi',
        'cognitive assistance kholo',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'cognitive_assistance',
          routeName: AppRoutes.cognitiveAssistance,
          ttsMessage: 'Opening Cognitive Assistance Dashboard.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open physical assistance',
        'physical assistance',
        'open physical assistant',
        'physical assistant',
        'fiscal assistance',
        'physicle assistance',
        'physical mode',
        'motor mode',
        'physical helper',
        'open physical',
        'physical',
        'शारीरिक सहायता',
        'physical assistance open cheyyi',
        'physical assistance open pannu',
        'physical assistance open maadi',
        'physical assistance kholo',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'physical_assistance',
          routeName: AppRoutes.physicalAssistance,
          ttsMessage: 'Opening Physical Assistance Dashboard.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open normal user',
        'normal user',
        'open normal mode',
        'normal mode',
        'general mode',
        'general user',
        'normal dashboard',
        'open normal dashboard',
        'normal user open cheyyi',
        'normal user open pannu',
        'normal user open maadi',
        'normal user kholo',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'normal_user',
          routeName: AppRoutes.normalUser,
          ttsMessage: 'Opening Normal User Suite.',
        );
        return;
      }

      // 6. SPECIFIC VISION SUB-FEATURE COMMANDS
      if (_isCommandMatch(clean, [
        'open object detection',
        'object detection',
        'detect objects',
        'identify object',
        'open object detector',
        'object detector',
        'objects detection',
        'detect object'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VISION_MODE] requested = Object Detection');
        try {
          final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
          await visionProvider.setVisionMode(VisionMode.identifyObject);
        } catch (_) {}
        debugPrint('[VISION_MODE] active = identifyObject');
        debugPrint('[VOICE_FLOW] opened Object Detection');
        if (!context.mounted) return;
        await _executeNavigation(
          context,
          matchedCommand: 'object_detection',
          routeName: AppRoutes.vision,
          ttsMessage: 'Opening Object Detection.',
        );
        return;
      }

      if (_isCommandMatch(clean, ['open ocr', 'ocr', 'open read text', 'read text', 'text reader', 'scan text'])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VISION_MODE] requested = OCR');
        try {
          final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
          await visionProvider.setVisionMode(VisionMode.readText);
        } catch (_) {}
        debugPrint('[VISION_MODE] active = readText');
        debugPrint('[VOICE_FLOW] opened OCR');
        if (!context.mounted) return;
        await _executeNavigation(
          context,
          matchedCommand: 'ocr',
          routeName: AppRoutes.vision,
          ttsMessage: 'Opening OCR Text Reader.',
        );
        return;
      }

      // DOCUMENT READER & STORYBOOK VOICE COMMANDS
      if (_isCommandMatch(clean, ['import document', 'open document', 'load document', 'import story', 'select document'])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_DOC] Import document requested');
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.setVisionMode(VisionMode.readText);
            await visionProvider.importDocument();
          } catch (e) {
            debugPrint('[VOICE_DOC] Error triggering import: $e');
          }
        }
        return;
      }

      if (_isCommandMatch(clean, ['read this story', 'read story', 'start reading', 'read page'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.startReadingDocument();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['pause reading', 'pause story'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.pauseReadingDocument();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['resume reading', 'resume story'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.resumeReadingDocument();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['stop reading', 'stop story'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.stopReadingDocument();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['next page', 'page next', 'agla panna', 'agla page'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.nextPage();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['previous page', 'page back', 'pichla panna', 'pichla page'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.previousPage();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['what is this story about', 'summarize story', 'summarize document', 'story summary', 'tell me the story'])) {
        _consecutiveUnrecognizedCount = 0;
        if (context.mounted) {
          try {
            final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
            await visionProvider.summarizeActiveDocument();
          } catch (_) {}
        }
        return;
      }

      if (_isCommandMatch(clean, ['open scene description', 'scene description', 'describe surroundings', 'describe scene', 'surroundings'])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VISION_MODE] requested = Scene Description');
        try {
          final visionProvider = Provider.of<VisualAssistanceProvider>(context, listen: false);
          await visionProvider.setVisionMode(VisionMode.describeScene);
        } catch (_) {}
        debugPrint('[VISION_MODE] active = describeScene');
        debugPrint('[VOICE_FLOW] opened Scene Description');
        if (!context.mounted) return;
        await _executeNavigation(
          context,
          matchedCommand: 'scene_description',
          routeName: AppRoutes.vision,
          ttsMessage: 'Opening Scene Description.',
        );
        return;
      }

      if (_isCommandMatch(clean, ['open sign language', 'sign language', 'sign detection', 'sign'])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'sign_language',
          routeName: AppRoutes.signLanguage,
          ttsMessage: 'Opening Sign Language Translator.',
        );
        return;
      }

      // 8. SPEECH ASSISTANCE & TRANSLATOR
      if (_isCommandMatch(clean, [
        'open voice assistant', 'voice assistant', 'open speech assistance', 'speech assistance', 'ai assistant', 'speech support', 'बोलना', 'ಮಾತು',
        'speech assistance open cheyyi', 'speech assistance open pannu',
        'speech assistance open maadi', 'speech assistance kholo', 'bolna'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'speech_assistance',
          routeName: AppRoutes.aiAssistant,
          ttsMessage: 'Opening Speech AI Assistant.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open translator', 'translator', 'translate', 'अनुवाद', 'ಅನುವಾದ',
        'translator open cheyyi', 'translator open pannu',
        'translator open maadi', 'translator kholo', 'anuvadam', 'anuvad'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'translator',
          routeName: AppRoutes.translator,
          ttsMessage: 'Opening Translator.',
        );
        return;
      }

      // 9. TASKS, REMINDERS, NOTES
      if (_isCommandMatch(clean, [
        'open tasks', 'tasks', 'daily tasks', 'my tasks', 'task list', 'open task list', 'task', 'कार्य सूची',
        'daily tasks open cheyyi', 'daily tasks open pannu',
        'daily tasks open maadi', 'daily tasks kholo'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'daily_tasks',
          routeName: AppRoutes.todoList,
          ttsMessage: 'Opening Daily Tasks.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open reminders', 'open medication', 'reminders', 'medication', 'medication reminders', 'reminder', 'दवा', 'ಔಷಧಿ',
        'reminders open cheyyi', 'reminders open pannu',
        'reminders open maadi', 'reminders kholo', 'dawa'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'reminders',
          routeName: AppRoutes.reminders,
          ttsMessage: 'Opening Reminders and Medication.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'open notes', 'notes', 'memory notes', 'my notes', 'note', 'नोट्स',
        'notes open cheyyi', 'notes open pannu',
        'notes open maadi', 'notes kholo'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'notes',
          routeName: AppRoutes.notes,
          ttsMessage: 'Opening Notes and Memory.',
        );
        return;
      }

      // 10. PROFILE & SETTINGS
      if (_isCommandMatch(clean, [
        'profile', 'my profile', 'open profile', 'प्रोफाइल',
        'profile open cheyyi', 'profile open pannu',
        'profile open maadi', 'profile kholo'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'profile',
          routeName: AppRoutes.profile,
          ttsMessage: 'Opening Profile and Settings.',
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'settings', 'open settings', 'accessibility settings', 'सेटिंग्स', 'ಸೇಟಿಂಗ್ಸ್',
        'settings open cheyyi', 'settings open pannu',
        'settings open maadi', 'settings kholo'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'settings',
          routeName: AppRoutes.accessibilitySettings,
          ttsMessage: 'Opening Accessibility Settings.',
        );
        return;
      }

      // 11. GENERAL NAVIGATION: GO HOME & GO BACK
      if (_isCommandMatch(clean, [
        'home', 'go home', 'main menu', 'open home', 'होम पर जाओ', 'ಹೋಮ್ಗೆ ಹೋಗು', 'முகப்புக்கு செல்',
        'home ki vellu', 'home ki po', 'home ku po', 'home ge hogi', 'home pe chalo',
        'home chalo', 'wapas jao', 'ghar chalo', 'home lo', 'home ku thirumbu', 'home ge thirugi',
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'home',
          routeName: AppRoutes.home,
          ttsMessage: 'Returning to Home Dashboard.',
          removeUntil: true,
        );
        return;
      }

      if (_isCommandMatch(clean, [
        'go back', 'back', 'return', 'पीछे जाओ', 'ಹಿಂದೆ ಹೋಗಿ', 'பின்னால் செல்',
        'venakki po', 'venakki vellu', 'penniki vellu', 'pinnaal po', 'pinnaadi po',
        'hinde hogi', 'hinde banni', 'piche jao'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        await _executePop(context);
        return;
      }

      // 12. ASSISTANCE PROFILE CONFIGURATION
      if (clean.contains('assistance profile') || clean.contains('assistance type') || clean.contains('change profile') || clean.contains('setup profile')) {
        _consecutiveUnrecognizedCount = 0;
        await _executeNavigation(
          context,
          matchedCommand: 'assistance_setup',
          routeName: AppRoutes.assistanceSetup,
          ttsMessage: 'Opening Assistance Setup.',
        );
        return;
      }

      if (clean == 'continue' || clean == 'save' || clean == 'done' || clean == 'finish' || clean == 'आगे बढ़ें' || clean == 'ಮುಂದುವರೆಯಿರಿ') {
        _consecutiveUnrecognizedCount = 0;
        await speakConfirmation("Assistance profile saved. Welcome to ADIUVA.");
        final navState = AppRoutes.navigatorKey.currentState;
        if (navState != null) {
          navState.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        } else if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
        return;
      }

      List<String> targetProfiles = [];
      if (clean.contains('blind') || clean.contains('visually impaired')) targetProfiles.add('blind');
      if (clean.contains('deaf') || clean.contains('hard of hearing') || clean.contains('hearing impaired')) targetProfiles.add('deaf');
      if (clean.contains('speech') || clean.contains('speech difficulty') || clean.contains('speaking')) targetProfiles.add('speech');
      if (clean.contains('physical') || clean.contains('physically disabled') || clean.contains('motor')) targetProfiles.add('physical');
      if (clean.contains('general profile') || clean.contains('normal user profile') || (_currentScreenContext == 'disability_selection' && (clean.contains('general') || clean.contains('normal user')))) {
        targetProfiles.add('general');
      }

      if (targetProfiles.isNotEmpty) {
        _consecutiveUnrecognizedCount = 0;
        String locale = 'en-IN';
        if (context.mounted) {
          try {
            locale = Provider.of<AccessibilityProvider>(context, listen: false).speechLocale;
          } catch (_) {}
        }
        await speakConfirmation(VoiceResponseLocalizer.modeSelected(targetProfiles.join(', '), locale));
        return;
      }
      // STEP 5 — EMERGENCY SOS
      if (_isEmergencyCommand(clean)) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_NAV_DEBUG] matched command = emergency');
        debugPrint('[VOICE_DEVICE] command matched = emergency');
        await _executeNavigation(
          context,
          matchedCommand: 'emergency',
          routeName: AppRoutes.emergencySos,
          ttsMessage: 'Opening Emergency SOS.',
        );
        return;
      }

      // STEP 5B — LOCATION COMMAND FALLBACK
      if (_isCommandMatch(clean, [
        'location', 'open location', 'location screen', 'location page', 'where am i screen',
        'where am i', 'what is my location', 'tell me my location', 'my current location',
        'current location', 'show my location', 'where am i right now', 'please tell me where i am',
        'could you please tell me my current location', 'can you tell me where i am', 'show location',
        'tell my location', 'where i am', 'my location',
        'स्थान', 'मेरी लोकेशन', 'मेरा स्थान', 'लोकेशन', 'मैं कहाँ हूँ', 'main kahan hoon', 'meri location', 'mera sthaan',
        'naan engae irukkiren', 'நான் எங்கே இருக்கிறேன்', 'naan engae irukken', 'இடம்', 'என் இருப்பிடம்', 'என் இடம்', 'இருப்பிடம்', 'idaam', 'idam', 'en iruppidam',
        'nenu ekkada unnanu', 'నేను ఎక్కడ ఉన్నాను', 'నేను ఎక్కడ ఉన్నా', 'స్థానం', 'నా స్థానం', 'నా లొకేషన్', 'sthaanam', 'naa sthaanam', 'naa location',
        'naanu elliddene', 'ನಾನು ಎಲ್ಲಿದ್ದೇನೆ', 'ಸ್ಥಳ', 'ನನ್ನ ಸ್ಥಳ', 'ನನ್ನ ಲೊಕೇಶನ್', 'sthala', 'nanna sthala', 'nanna location'
      ])) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_LOCATION_FALLBACK] Matched location command fallback: "$clean"');
        final navState = AppRoutes.navigatorKey.currentState;
        if (navState != null) {
          navState.pushNamed(AppRoutes.location);
        } else if (context.mounted) {
          Navigator.of(context).pushNamed(AppRoutes.location);
        }
        String locationSpeech = VoiceResponseLocalizer.formatLocationResponse(_currentLanguageCode, '');
        if (context.mounted) {
          try {
            final physProvider = Provider.of<PhysicalAssistanceProvider>(context, listen: false);
            await physProvider.fetchCurrentLocation(requestPermissionIfDenied: true);
            if (physProvider.locationError != null && physProvider.currentAddress.isEmpty) {
              locationSpeech = physProvider.locationError!;
            } else if (physProvider.currentAddress.isNotEmpty) {
              locationSpeech = VoiceResponseLocalizer.formatLocationResponse(
                _currentLanguageCode,
                physProvider.currentAddress,
              );
            }
          } catch (e) {
            debugPrint('[LOCATION_TRACE] error $e');
          }
        }
        await speakConfirmation(locationSpeech);
        return;
      }

      // STEP 6 — HELP COMMAND
      if (_isHelpCommand(clean)) {
        _consecutiveUnrecognizedCount = 0;
        debugPrint('[VOICE_NAV_DEBUG] matched command = help');
        debugPrint('[VOICE_DEVICE] command matched = help');
        await _handleHelpCommand();
        return;
      }

      // LAYER 2 CONVERSATIONAL PHRASE RESOLUTION
      final conversationalPhrase = VoiceResponseLocalizer.resolveConversationalPhrase(rawCommand, _currentLanguageCode);
      if (conversationalPhrase != null) {
        _consecutiveUnrecognizedCount = 0;
        final display = conversationalPhrase.getDisplayString(_currentLanguageCode);
        debugPrint('[VOICE_CONVERSATIONAL] phrase matched = ${conversationalPhrase.intent}');
        await speakConfirmation(display);
        return;
      }

      // 13. UNRECOGNIZED COMMAND FALLBACK
      debugPrint('[VOICE_NAV_DEBUG] matched command = none');
      debugPrint('[VOICE_RUNTIME] command matched = none');
      debugPrint('[VOICE_RUNTIME] command executed = false');

      _consecutiveUnrecognizedCount++;
      debugPrint('[VOICE_RUNTIME] Unrecognized command count: $_consecutiveUnrecognizedCount');
      debugPrint('[VOICE_UNRECOGNIZED] raw="$rawCommand" clean="$clean"');

      if (_consecutiveUnrecognizedCount == 1) {
        final String unrecognizedMessage = VoiceResponseLocalizer.unrecognizedCommand(clean, _currentLanguageCode);
        await speakConfirmation(unrecognizedMessage);
      } else if (_consecutiveUnrecognizedCount == 2) {
        final String subtleHint = VoiceResponseLocalizer.unrecognizedSubtleHint(_currentLanguageCode);
        if (subtleHint.isNotEmpty) {
          await speakConfirmation(subtleHint);
        } else {
          final String unrecognizedMessage = VoiceResponseLocalizer.unrecognizedCommand(clean, _currentLanguageCode);
          await speakConfirmation(unrecognizedMessage);
        }
      } else {
        await _handleHelpCommand();
        _consecutiveUnrecognizedCount = 0;
      }
    } finally {
      _isExecutingCommand = false;
      debugPrint('[VOICE_RUNTIME] command lock released');
      if (_state != GlobalVoiceState.listening && _state != GlobalVoiceState.speaking) {
        _setVoiceState(GlobalVoiceState.idle, reason: "Command processed");
      }
      if (_isAutoVoiceEnabled && !_isYieldedToFeature && !_ttsService.isSpeaking && _state == GlobalVoiceState.idle) {
        final ctx = _safeGlobalContext;
        if (ctx != null && ctx.mounted) {
          debugPrint('[VOICE_RUNTIME] Resuming auto-listening after command processing');
          await triggerAutoListening(ctx);
        }
      }
    }
  }

  bool _isEmergencyCommand(String clean) {
    if (clean.contains('help help') ||
        clean.contains('emergency') ||
        clean == 'sos' ||
        clean.contains('sos') ||
        clean.contains('bachao') ||
        clean.contains('aapathu') ||
        clean.contains('kaappatru') ||
        clean.contains('aapathukal') ||
        clean.contains('इमरजेंसी') ||
        clean.contains('बचाओ') ||
        clean.contains('आपत्कालीन') ||
        clean.contains('ಆಪತ್ತು') ||
        clean.contains('ಕಾಪಾಡಿ')) {
      return true;
    }
    return false;
  }

  bool _isHelpCommand(String clean) {
    if (clean == 'help' ||
        clean == 'commands' ||
        clean == 'options' ||
        clean.contains('what can i say') ||
        clean.contains('help me') ||
        clean == 'available commands' ||
        clean == 'what are the commands' ||
        clean == 'tell me available commands' ||
        clean == 'show available commands' ||
        clean == 'list commands' ||
        clean == 'show commands' ||
        clean == 'मदद' ||
        clean == 'सहायता' ||
        clean == 'ಸಹಾಯ' ||
        clean == 'உதவி' ||
        clean == 'సహాయం') {
      return true;
    }
    return false;
  }

  bool _isCommandMatch(String cleanInput, List<String> patterns) {
    for (final pattern in patterns) {
      if (cleanInput == pattern || cleanInput.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Context-Aware Help Instruction Announcement
  Future<void> _handleHelpCommand() async {
    debugPrint('[VOICE_COMMAND] Handling help command for context: $_currentScreenContext');
    String locale = 'en-IN';
    if (_activeContext != null && _activeContext!.mounted) {
      try {
        locale = Provider.of<AccessibilityProvider>(_activeContext!, listen: false).speechLocale;
      } catch (_) {}
    }
    await speakConfirmation(VoiceResponseLocalizer.helpMessage(locale, _currentScreenContext));
  }

  @override
  void dispose() {
    _welcomeFallbackTimer?.cancel();
    if (_onWelcomeTtsCallback != null) {
      _ttsService.removeCompletionListener(_onWelcomeTtsCallback!);
    }
    super.dispose();
  }
}
