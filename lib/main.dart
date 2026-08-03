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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint("Firebase OK");

    final storage = LocalStorageService();
    await storage.init();

    debugPrint("Storage OK");

    final language = LanguageService();
    await language.init();

    debugPrint("Language OK");

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

    debugPrint("runApp()");
  } catch (e, stack) {
    debugPrint(e.toString());
    debugPrint(stack.toString());

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              e.toString(),
            ),
          ),
        ),
      ),
    );
  }
}
