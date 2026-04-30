import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/features/screens/home/home_screen.dart';
import 'package:little_johor_explorer/features/screens/ai_features/chat_with_history_screen.dart';
import 'package:little_johor_explorer/features/screens/family/family_chat_screen.dart';
import 'package:little_johor_explorer/features/screens/home/progress_screen.dart';
import 'package:little_johor_explorer/features/screens/profile/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ChatWithHistoryScreen(),
    const FamilyChatScreen(),
    const ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: SizedBox(
          height: 80,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: lang.translate('tab_home')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.smart_toy),
                  label: lang.translate('tab_bot')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.groups),
                  label: lang.translate('tab_family')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.insights),
                  label: lang.translate('tab_progress')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: lang.translate('tab_profile')),
            ],
          ),
        ));
  }
}
