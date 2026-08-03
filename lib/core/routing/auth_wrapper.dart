import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/features/screens/auth/login_screen.dart';
import 'package:little_johor_explorer/features/screens/main_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("AuthWrapper build");

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        debugPrint("Consumer rebuilding");
        debugPrint("Loading = ${authService.isLoading}");

        if (authService.isLoading) {
          debugPrint("Still loading...");

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        debugPrint("Loading finished");

        if (authService.currentUser == null) {
          debugPrint("Go Login");

          return const LoginScreen();
        }

        debugPrint("Go Main");

        return const MainWrapper();
      },
    );
  }
}
