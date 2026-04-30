import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'local_storage_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _auth.authStateChanges().listen((fb_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        await _fetchAndSetUser(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchAndSetUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data()!;

        if (userData['role'] == 'parent') {
          // ⭐️ INTEGRATED SORTING: Oldest (first added) at the top
          final childrenSnapshot = await _firestore
              .collection('users')
              .where('parentId', isEqualTo: uid)
              .orderBy('createdAt', descending: false)
              .get();

          List<Map<String, dynamic>> childrenList =
              childrenSnapshot.docs.map((doc) => doc.data()).toList();

          userData['children'] = childrenList;
        }

        _currentUser = _mapToUser(userData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  User _mapToUser(Map<String, dynamic> userData) {
    String role = userData['role']?.toString() ?? 'parent';
    String email = userData['email']?.toString() ?? '';
    String id = userData['uid']?.toString() ?? userData['id']?.toString() ?? '';
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

  Future<bool> login(
      {required String email,
      required String password,
      LocalStorageService? storage}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        await _fetchAndSetUser(credential.user!.uid);
        if (storage != null) storage.setCurrentUser(_currentUser!.id);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login failed: $e");
      return false;
    }
  }

  Future<bool> register({
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
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Registration failed: $e");
      return false;
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

        // Delete each child's Auth account via Cloud Function first
        String? idToken = await user.getIdToken();
        for (var childDoc in childrenSnapshot.docs) {
          final childId = childDoc.id;
          try {
            if (idToken != null) {
              final url =
                  'https://us-central1-little-johor-explorer-db.cloudfunctions.net/deleteChildAuth';
              await http.post(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $idToken',
                },
                body: jsonEncode({
                  "data": {"childUid": childId}
                }),
              );
            }
          } catch (e) {
            debugPrint("Failed to delete child auth $childId: $e");
          }
          await childDoc.reference.delete();
          await _firestore.collection('progress').doc(childId).delete();
        }

        // Delete parent's Firestore doc
        await _firestore.collection('users').doc(parentUid).delete();
        await _firestore.collection('progress').doc(parentUid).delete();

        // Delete parent's Auth account
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
      throw Exception(errorMessage); // Throw to be caught by the UI try-catch
    } catch (e) {
      debugPrint("Child registration failed (General): $e");
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> editChild({
    required String childId,
    required String newName,
    String? newPassword,
    String? newAvatarUrl,
  }) async {
    if (_currentUser == null) return false;
    try {
      Map<String, dynamic> updates = {'displayName': newName};
      if (newAvatarUrl != null) updates['avatarUrl'] = newAvatarUrl;
      await _firestore.collection('users').doc(childId).update(updates);

      if (newPassword != null && newPassword.isNotEmpty) {
        try {
          String? idToken = await _auth.currentUser?.getIdToken();

          if (idToken != null) {
            final String url =
                'https://us-central1-little-johor-explorer-db.cloudfunctions.net/updateChildPassword';
            final response = await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({
                "data": {
                  "childUid": childId,
                  "newPassword": newPassword,
                }
              }),
            );

            if (response.statusCode != 200) {
              debugPrint("HTTP Function Error: ${response.body}");
              return false;
            }
            debugPrint("Password successfully updated via HTTP!");
          }
        } catch (e) {
          debugPrint("Failed to update password via HTTP: $e");
          return false;
        }
      }

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
      // Call Cloud Function to delete Auth account
      String? idToken = await _auth.currentUser?.getIdToken();
      if (idToken != null) {
        final url =
            'https://us-central1-little-johor-explorer-db.cloudfunctions.net/deleteChildAuth';
        await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            "data": {"childUid": childId}
          }),
        );
      }

      // Delete Firestore documents
      await _firestore.collection('users').doc(childId).delete();
      await _firestore.collection('progress').doc(childId).delete();

      await _fetchAndSetUser(_currentUser!.id);
      notifyListeners();
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

  Future<bool> updatePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      debugPrint("Password update failed: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
