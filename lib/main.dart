import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:little_johor_explorer/app.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/data/services/gemini_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/chat_service.dart';
import 'package:little_johor_explorer/data/services/progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase OK");

    // 2. Initialize Storage
    final storage = LocalStorageService();
    await storage.init();
    debugPrint("Storage OK");

    // 3. Initialize Language Service
    final language = LanguageService();
    await language.init();
    debugPrint("Language OK");

    // 4. Run App inside the single try-block
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthService(),
          ),
          ChangeNotifierProvider.value(
            value: storage,
          ),
          ChangeNotifierProvider(
            create: (_) => StoryService(storage),
          ),
          ChangeNotifierProvider(
            create: (_) => GeminiService(),
          ),
          ChangeNotifierProvider.value(
            value: language,
          ),
          ChangeNotifierProvider(
            create: (_) => ProgressService(),
          ),
          Provider(
            create: (_) => ChatService(),
          ),
        ],
        child: const LittleJohorExplorerApp(),
      ),
    );

    debugPrint("runApp() OK");
  } catch (e, stack) {
    debugPrint("Initialization Error: $e");
    debugPrint(stack.toString());

    // Fallback UI in case of startup failure
    // Fallback UI in case of startup failure
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              // 👈 Changed 'field:' to 'child:' here
              child: Text(
                "App Initialization Error:\n$e",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
