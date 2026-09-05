import 'package:get_it/get_it.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/camera_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/signup_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/provider/auth_provider.dart';
import '../../features/speech_assistance/presentation/provider/speech_assistance_provider.dart';
import '../../features/speech_assistance/presentation/provider/voice_mode_provider.dart';
import '../../features/visual_assistance/data/datasources/ml_kit_ocr_service.dart';
import '../../features/visual_assistance/data/datasources/yolo_tflite_service.dart';
import '../../features/visual_assistance/data/datasources/ml_kit_barcode_service.dart';
import '../../features/visual_assistance/data/datasources/scene_description_service.dart';
import '../../features/visual_assistance/presentation/provider/visual_assistance_provider.dart';
import '../../features/accessibility/presentation/provider/accessibility_provider.dart';
import '../../features/emergency_sos/data/datasources/emergency_remote_datasource.dart';
import '../../features/emergency_sos/presentation/provider/emergency_sos_provider.dart';

/// Global Service Locator Instance (GetIt)
final GetIt sl = GetIt.instance;

/// Initialize Service Locator & Register Dependencies
Future<void> setupServiceLocator() async {
  // ==================== CORE SERVICES ====================
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  sl.registerLazySingleton<TtsService>(() => TtsService());
  sl.registerLazySingleton<SttService>(() => SttService());
  sl.registerLazySingleton<CameraService>(() => CameraService());

  // ==================== AUTH FEATURE ====================
  // Data Sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(localStorageService: sl<LocalStorageService>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: sl<AuthRemoteDataSource>(),
      authLocalDataSource: sl<AuthLocalDataSource>(),
      firebaseService: sl<FirebaseService>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignupUseCase>(
    () => SignupUseCase(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ResetPasswordUseCase>(
    () => ResetPasswordUseCase(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(authRepository: sl<AuthRepository>()),
  );

  // Providers
  sl.registerFactory<AuthProvider>(
    () => AuthProvider(
      loginUseCase: sl<LoginUseCase>(),
      signupUseCase: sl<SignupUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ==================== ACCESSIBILITY & SETTINGS FEATURE ====================
  sl.registerFactory<AccessibilityProvider>(
    () => AccessibilityProvider(
      localStorageService: sl<LocalStorageService>(),
      ttsService: sl<TtsService>(),
    ),
  );

  // ==================== EMERGENCY SOS FEATURE ====================
  sl.registerLazySingleton<EmergencyRemoteDataSource>(
    () => EmergencyRemoteDataSource(),
  );

  sl.registerFactory<EmergencySosProvider>(
    () => EmergencySosProvider(
      remoteDataSource: sl<EmergencyRemoteDataSource>(),
      ttsService: sl<TtsService>(),
    ),
  );

  // ==================== SPEECH / AI ASSISTANT FEATURE ====================
  sl.registerFactory<SpeechAssistanceProvider>(
    () => SpeechAssistanceProvider(ttsService: sl<TtsService>()),
  );

  sl.registerFactory<VoiceModeProvider>(
    () => VoiceModeProvider(
      sttService: sl<SttService>(),
      ttsService: sl<TtsService>(),
    ),
  );

  // ==================== VISION FEATURE ====================
  sl.registerLazySingleton<MlKitOcrService>(() => MlKitOcrService());
  sl.registerLazySingleton<YoloTfliteService>(() => YoloTfliteService());
  sl.registerLazySingleton<MlKitBarcodeService>(() => MlKitBarcodeService());
  sl.registerLazySingleton<SceneDescriptionService>(() => SceneDescriptionService());

  sl.registerFactory<VisualAssistanceProvider>(
    () => VisualAssistanceProvider(
      cameraService: sl<CameraService>(),
      ocrService: sl<MlKitOcrService>(),
      detectionService: sl<YoloTfliteService>(),
      barcodeService: sl<MlKitBarcodeService>(),
      sceneService: sl<SceneDescriptionService>(),
      ttsService: sl<TtsService>(),
    ),
  );
}
