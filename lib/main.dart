import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routing/auth_wrapper.dart';
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
    debugPrint("✅ Firebase Initialized Successfully");

    final localStorageService = LocalStorageService();
    await localStorageService.init().timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              debugPrint("⚠️ LocalStorage Init Timeout - Proceeding anyway"),
        );

    final languageService = LanguageService();
    await languageService.init();

    final authService = AuthService();
    final storyService = StoryService(localStorageService);
    final geminiService = GeminiService();
    final chatService = ChatService();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService),
          ChangeNotifierProvider.value(value: localStorageService),
          ChangeNotifierProvider.value(value: storyService),
          ChangeNotifierProvider.value(value: geminiService),
          ChangeNotifierProvider.value(value: languageService),
          ChangeNotifierProvider(create: (_) => ProgressService()),
          Provider.value(value: chatService),
        ],
        child: const LittleJohorExplorerApp(),
      ),
    );
  } catch (e) {
    debugPrint("❌ Initialization Error: $e");
    runApp(const LittleJohorExplorerApp());
  }
}
