import 'package:flutter/material.dart';
import 'package:little_johor_explorer/features/screens/auth/login_screen.dart';
import 'package:little_johor_explorer/features/screens/auth/register_screen.dart';
import 'package:little_johor_explorer/features/screens/main_wrapper.dart';
import 'package:little_johor_explorer/features/screens/home/story_reader_screen.dart';
import 'package:little_johor_explorer/features/screens/ai_features/chat_with_history_screen.dart';
import 'package:little_johor_explorer/features/screens/family/family_chat_screen.dart';
import 'package:little_johor_explorer/features/screens/profile/profile_screen.dart';
import 'package:little_johor_explorer/features/screens/home/category_quiz_screen.dart';
import 'package:little_johor_explorer/features/screens/home/progress_screen.dart';
import 'package:little_johor_explorer/features/screens/parent/parent_dashboard.dart';
import 'package:little_johor_explorer/core/constants/routes.dart';
import 'core/routing/auth_wrapper.dart';

class LittleJohorExplorerApp extends StatelessWidget {
  const LittleJohorExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little Johor Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
        fontFamily: 'NotoSans',
        fontFamilyFallback: const [
          'Apple Color Emoji',
          'Segoe UI Emoji',
          'Noto Color Emoji',
        ],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.home: (context) => const MainWrapper(),
        Routes.storyReader: (context) => const StoryReaderScreen(),
        Routes.quiz: (context) => const CategoryQuizScreen(),
        Routes.aiChat: (context) => const ChatWithHistoryScreen(),
        Routes.familyHub: (context) => const FamilyChatScreen(),
        Routes.profile: (context) => ProfileScreen(),
        Routes.parentDashboard: (context) => const ParentDashboard(),
        Routes.progress: (context) => const ProgressScreen(),
      },
    );
  }
}
