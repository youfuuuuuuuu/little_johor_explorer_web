import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final bool isAdmin = authService.currentUser?.role == 'admin';
    final List<Widget> pages = [
      const HomeScreen(),
      const ChatWithHistoryScreen(),
      if (!isAdmin) const FamilyChatScreen(),
      if (!isAdmin) const ProgressScreen(),
      ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
          icon: const Icon(Icons.home), label: lang.translate('tab_home')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.smart_toy), label: lang.translate('tab_bot')),
      if (!isAdmin)
        BottomNavigationBarItem(
            icon: const Icon(Icons.groups),
            label: lang.translate('tab_family')),
      if (!isAdmin)
        BottomNavigationBarItem(
            icon: const Icon(Icons.insights),
            label: lang.translate('tab_progress')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.person), label: lang.translate('tab_profile')),
    ];

    int safeIndex = _currentIndex;
    if (safeIndex >= pages.length) {
      safeIndex = pages.length - 1;
    }

    return Scaffold(
        body: pages[safeIndex],
        bottomNavigationBar: SizedBox(
          height: 80,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: safeIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: navItems,
          ),
        ));
  }
}
