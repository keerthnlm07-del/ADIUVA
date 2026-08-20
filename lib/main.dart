import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AdiuvaApp());
}

class AdiuvaApp extends StatelessWidget {
  const AdiuvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adiuva',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GeminiTestPage(),
    );
  }
}

class GeminiTestPage extends StatefulWidget {
  const GeminiTestPage({super.key});

  @override
  State<GeminiTestPage> createState() => _GeminiTestPageState();
}

class _GeminiTestPageState extends State<GeminiTestPage> {
  String responseText = 'Tap the button to test Gemini.';

  Future<void> testGemini() async {
    setState(() {
      responseText = 'Gemini is thinking...';
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.6-flash',
      );

      final response = await model.generateContent([
        Content.text('Say hello to Adiuva in one short sentence.')
      ]);

      setState(() {
        responseText = response.text ?? 'No response received.';
      });
    } catch (e) {
      setState(() {
        responseText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adiuva'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Gemini AI Test',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                responseText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: testGemini,
                child: const Text('Test Gemini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}