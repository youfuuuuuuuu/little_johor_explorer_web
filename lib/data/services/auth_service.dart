import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'local_storage_service.dart';

class AuthService extends ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthService() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    debugPrint("===== INIT AUTH START =====");

    try {
      final firebaseUser = _auth.currentUser;
      debugPrint("Firebase currentUser = ${firebaseUser?.uid}");

      if (firebaseUser != null) {
        debugPrint("Fetching Firestore user...");
        await _fetchAndSetUser(firebaseUser.uid);
        debugPrint("Fetch complete.");
      } else {
        debugPrint("No logged in user.");
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e, s) {
      debugPrint("INIT AUTH ERROR");
      debugPrint(e.toString());
      debugPrint(s.toString());

      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }

    _auth.authStateChanges().listen((fb_auth.User? firebaseUser) async {
      debugPrint("Auth state changed -> ${firebaseUser?.uid}");

      if (firebaseUser != null) {
        await _fetchAndSetUser(firebaseUser.uid);
      } else {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchAndSetUser(String uid) async {
    debugPrint("Start _fetchAndSetUser");

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("Before Firestore");
      final doc = await _firestore.collection('users').doc(uid).get();
      debugPrint("After Firestore");

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data()!;

        if (userData['role'] == 'parent') {
          final childrenSnapshot = await _firestore
              .collection('users')
              .where('parentId', isEqualTo: uid)
              .orderBy('createdAt', descending: false)
              .get();

          List<Map<String, dynamic>> childrenList =
              childrenSnapshot.docs.map((doc) => doc.data()).toList();

          userData['children'] = childrenList;
        }

        _currentUser = _mapToUser(userData, uid);
      } else {
        debugPrint(
            "User document does not exist for UID: $uid. Creating temporary recovery profile.");

        _currentUser = User(
          id: uid,
          email: _auth.currentUser?.email ?? "",
          displayName: "Explorer",
          role: "parent",
          avatarUrl: null,
        );
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
      throw Exception("Failed to retrieve user profile data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  User _mapToUser(Map<String, dynamic> userData, String uid) {
    String role = userData['role']?.toString() ?? 'parent';
    String email = userData['email']?.toString() ?? '';
    String id =
        userData['uid']?.toString() ?? userData['id']?.toString() ?? uid;
    String name = userData['displayName'] ?? userData['name'] ?? 'Explorer';
    String? avatar = userData['avatarUrl']?.toString();

    if (role == 'parent') {
      List<ChildProfile> savedChildren = [];
      if (userData['children'] != null) {
        savedChildren = (userData['children'] as List).map((c) {
          return ChildProfile(
            id: c['uid']?.toString() ?? c['id']?.toString() ?? '',
            email: c['email']?.toString() ?? '',
            name: c['displayName']?.toString() ?? c['name']?.toString() ?? '',
            avatarUrl: c['avatarUrl']?.toString(),
            parentId: id,
          );
        }).toList();
      }
      return ParentProfile(
        id: id,
        email: email,
        displayName: name,
        role: role,
        avatarUrl: avatar,
        children: savedChildren,
      );
    } else if (role == 'child') {
      return ChildProfile(
        id: id,
        email: email,
        name: name,
        avatarUrl: avatar,
        parentId: userData['parentId']?.toString() ?? '',
      );
    }
    return User(
        id: id, email: email, displayName: name, role: role, avatarUrl: avatar);
  }

  String getChildEmail(String childId) {
    if (_currentUser is ParentProfile) {
      final parent = _currentUser as ParentProfile;
      try {
        return parent.children.firstWhere((c) => c.id == childId).email;
      } catch (e) {
        return "";
      }
    }
    return "";
  }

  Future<String?> login({
    required String email,
    required String password,
    LocalStorageService? storage,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (credential.user != null) {
        await _fetchAndSetUser(credential.user!.uid);
        if (storage != null) storage.setCurrentUser(_currentUser!.id);
        return null;
      }
      return "Login failed. Please try again later.";
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "The email is not registered. Please check your input or register a new account.";
        case 'wrong-password':
          return "The password is incorrect. Please try again.";
        case 'invalid-email':
          return "The email format is invalid.";
        case 'user-disabled':
          return "This account has been disabled.";
        case 'too-many-requests':
          return "Too many login attempts. Please try again later.";
        default:
          return "Login failed: ${e.message}";
      }
    } catch (e) {
      return "An unknown error occurred: $e";
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? avatarUrl,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'displayName': displayName,
          'role': role,
          'avatarUrl': avatarUrl,
          'children': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        await Future.delayed(const Duration(milliseconds: 600));

        return null;
      }
      return "Registration failed.";
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "The email is already in use. Please log in instead.";
      } else if (e.code == 'weak-password') {
        return "The password is too weak. Please set a more complex password.";
      }
      return "Registration error: ${e.message}";
    } catch (e) {
      return "Registration failed: $e";
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        String parentUid = user.uid;

        final childrenSnapshot = await _firestore
            .collection('users')
            .where('parentId', isEqualTo: parentUid)
            .get();

        for (var childDoc in childrenSnapshot.docs) {
          await childDoc.reference.delete();
          await _firestore.collection('progress').doc(childDoc.id).delete();
        }

        await _firestore.collection('users').doc(parentUid).delete();
        await _firestore.collection('progress').doc(parentUid).delete();

        await user.delete();

        _currentUser = null;
        notifyListeners();
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('requires-recent-login');
        }
        throw Exception(e.message);
      } catch (e) {
        debugPrint("Error deleting account: $e");
        throw Exception("An error occurred while deleting the account.");
      }
    }
  }

  Future<bool> registerChildAccount({
    required String email,
    required String password,
    required String childName,
    required String avatarUrl,
  }) async {
    if (_currentUser == null) return false;
    final String parentUid = _currentUser!.id;

    String tempAppName =
        "ChildCreation_${DateTime.now().millisecondsSinceEpoch}";

    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      fb_auth.UserCredential credential =
          await fb_auth.FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(email: email, password: password);

      final childUid = credential.user!.uid;

      await _firestore.collection('users').doc(childUid).set({
        'uid': childUid,
        'email': email,
        'displayName': childName,
        'role': 'child',
        'parentId': parentUid,
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryApp.delete();

      await _fetchAndSetUser(parentUid);
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }

      debugPrint("Child registration failed (Auth): $errorMessage");
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint("Child registration failed (General): $e");
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> editChild({
    required String childId,
    required String newName,
    String? newAvatarUrl,
  }) async {
    if (_currentUser == null) return false;
    try {
      Map<String, dynamic> updates = {'displayName': newName};
      if (newAvatarUrl != null) updates['avatarUrl'] = newAvatarUrl;
      await _firestore.collection('users').doc(childId).update(updates);

      await _fetchAndSetUser(_currentUser!.id);
      return true;
    } catch (e) {
      debugPrint("Edit child failed: $e");
      return false;
    }
  }

  Future<void> removeChild(String childId) async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(childId).delete();
      await _firestore.collection('progress').doc(childId).delete();

      await _fetchAndSetUser(_currentUser!.id);
    } catch (e) {
      debugPrint("Delete child failed: $e");
    }
  }

  Future<void> updateAvatar(String newAvatarUrl) async {
    if (_currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .update({'avatarUrl': newAvatarUrl});
    await _fetchAndSetUser(_currentUser!.id);
  }

  Future<bool> updateProfile({required String newName}) async {
    if (_currentUser == null) return false;
    await _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .update({'displayName': newName});
    await _fetchAndSetUser(_currentUser!.id);
    return true;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Critical Error during logout: $e");
    }
  }
}
