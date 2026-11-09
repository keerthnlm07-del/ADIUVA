# Flutter Proguard / R8 Rules for ADIUVA

# Suppress warnings for optional ML Kit modules and language components not bundled
-dontwarn com.google.mlkit.linkfirebase.FirebaseModelSource$Builder
-dontwarn com.google.mlkit.linkfirebase.FirebaseModelSource
-dontwarn com.google.mlkit.linkfirebase.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google_mlkit_**
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.**

# Keep ML Kit and TFLite plugin entrypoints
-keep class com.google_mlkit_image_labeling.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class org.tensorflow.lite.** { *; }
