import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/features/screens/auth/login_screen.dart';
import 'package:little_johor_explorer/features/screens/main_wrapper.dart';
import 'package:little_johor_explorer/features/screens/admin/admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && authService.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    if (!authService.isAuthenticated || authService.currentUser == null) {
      return const LoginScreen();
    }

    final String role = authService.currentUser!.role;

    if (role == 'admin') {
      return const AdminDashboardScreen();
    } else {
      return const MainWrapper();
    }
  }
}
