import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final List<String> _zooAvatars = [
    'assets/images/avatars/malayan_tiger.png',
    'assets/images/avatars/malayan_tapir.png',
    'assets/images/avatars/capybara.png',
    'assets/images/avatars/sun_bear.png',
    'assets/images/avatars/mandrill.png',
    'assets/images/avatars/saltwater_crocodile.png',
    'assets/images/avatars/wallaby.png',
    'assets/images/avatars/greater_flamingo.png',
  ];

  String _formatScreenTime(int totalMinutes, LanguageService lang) {
    try {
      if (totalMinutes < 60)
        return "$totalMinutes ${lang.translate('minutes_label').toLowerCase()}";
      return "${totalMinutes ~/ 60}h ${totalMinutes % 60}m";
    } catch (e) {
      return "0m";
    }
  }

  Stream<Map<String, dynamic>> _watchChildStats(String childId) {
    return FirebaseFirestore.instance
        .collection('progress')
        .doc(childId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {'stories': 0, 'quizzes': 0, 'badges': 0, 'screenTimeMins': 0};
      }
      final data = doc.data()!;
      final history = List<String>.from(data['history'] ?? []);
      int quizCount = history
          .where((item) => item.contains("Quiz:") || item.contains("Earned"))
          .length;
      return {
        'stories': (data['readStoryIds'] as List?)?.length ?? 0,
        'quizzes': quizCount,
        'badges': (data['earnedBadgeIds'] as List?)?.length ?? 0,
        'screenTimeMins': data['totalReadingTime'] ?? 0,
      };
    });
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green, // Green for success
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);

    final user = auth.currentUser;
    if (user == null || user.role != 'parent' || user is! ParentProfile) {
      return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
              child: CircularProgressIndicator(
                  color: Colors.black, strokeWidth: 2)));
    }

    final children = user.children;

    return Scaffold(
      backgroundColor: Colors.white, // Threads-style clean background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(children.length, lang, auth),
            const Divider(
                height: 1, color: Color(0xFFEEEEEE)), // Sharp separation
            Expanded(
              child: children.isEmpty
                  ? _buildEmptyState(lang)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: children.length,
                      itemBuilder: (context, index) =>
                          _buildChildCard(children[index], lang, auth),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count, LanguageService lang, AuthService auth) {
    final user = auth.currentUser as ParentProfile;
    final children = user.children;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          8, 12, 24, 12), // Adjusted for social alignment
      child: Row(
        children: [
          // Minimalist Back Trigger
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('parent_control'),
                  style: const TextStyle(
                    fontSize: 24, // Slightly larger
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -1.2, // Compressed for modern look
                  ),
                ),
                Text(
                  "${lang.translate('total_linked_children')}: $count / 5"
                      .toLowerCase(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Modern Floating Action Pill
          GestureDetector(
            onTap: () {
              if (children.length >= 5) {
                _showError(
                  context,
                  lang.currentLanguage == 'ms'
                      ? "Limit dicapai."
                      : "Limit reached.",
                );
              } else {
                _showAddChildDialog(context, auth, lang);
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(
      ChildProfile child, LanguageService lang, AuthService auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFF0F0F0), width: 1), // Flat border logic
      ),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _watchChildStats(child.id),
        builder: (context, snapshot) {
          final stats = snapshot.data ??
              {'stories': 0, 'quizzes': 0, 'screenTimeMins': 0};

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.black, width: 1.5), // Meta avatar style
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF5F5F5),
                  backgroundImage: child.avatarUrl != null
                      ? AssetImage(
                          child.avatarUrl!.replaceFirst('file:///', ''))
                      : null,
                ),
              ),
              title: Text(
                child.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.3),
              ),
              subtitle: Text(
                "view activity stats",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400),
              ),
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statItem(
                              "${stats['stories']}", "read", Colors.black),
                          _statItem(
                              "${stats['quizzes']}", "quiz", Colors.black),
                          _statItem(
                              _formatScreenTime(stats['screenTimeMins'], lang),
                              "time",
                              Colors.black),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showEditDialog(context, auth, child, lang),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5F5F5),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Edit profile",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _confirmDelete(
                                context, auth, child.id, child.name, lang),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 20),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.05)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
              letterSpacing: -0.5),
        ),
        Text(
          label.toLowerCase(),
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState(LanguageService lang) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.face_retouching_natural_rounded, // More modern icon
          size: 64,
          color: Colors.grey.shade200),
      const SizedBox(height: 16),
      Text(lang.translate('no_childs').toLowerCase(),
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
              letterSpacing: -0.2)),
    ]));
  }

  void _showAddChildDialog(
      BuildContext context, AuthService auth, LanguageService lang) {
    final emailC = TextEditingController();
    final nameC = TextEditingController();
    final passC = TextEditingController();
    final confC = TextEditingController();
    String avatar = _zooAvatars[0];
    bool isSaving = false;
    bool obsP = true;
    bool obsC = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: const Color(0xFFF8F9FE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Text(lang.translate('new_child_account'),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: Colors.black)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () => _openAvatarPicker(
                      context, lang, (p) => setS(() => avatar = p)),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage(avatar),
                          backgroundColor: Colors.white),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildCardWrapper(
                    title: lang.translate('user_info'),
                    children: [
                      _buildStyledField(
                          controller: nameC,
                          label: lang.translate('child_name'),
                          icon: Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildStyledField(
                          controller: emailC,
                          label: lang.translate('login_email'),
                          icon: Icons.email_outlined),
                    ]),
                const SizedBox(height: 20),
                _buildCardWrapper(title: lang.translate('security'), children: [
                  _buildPasswordField(lang.translate('password'), passC, obsP,
                      () => setS(() => obsP = !obsP)),
                  const SizedBox(height: 15),
                  _buildPasswordField(lang.translate('confirm_new_password'),
                      confC, obsC, () => setS(() => obsC = !obsC)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.translate('cancel'),
                    style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameC.text.trim().isEmpty) {
                        _showError(context, "Please enter child's name.");
                        return;
                      }
                      if (emailC.text.trim().isEmpty) {
                        _showError(context, "Please enter email.");
                        return;
                      }
                      if (passC.text.length < 8) {
                        _showError(
                            context, "Password must be at least 8 characters.");
                        return;
                      }

                      if (passC.text != confC.text) {
                        _showError(
                            context,
                            lang.currentLanguage == 'ms'
                                ? "Kata laluan tidak sepadan!"
                                : "Passwords do not match!");
                        return;
                      }

                      setS(() => isSaving = true);

                      try {
                        // Call registration service
                        bool success = await auth.registerChildAccount(
                          email: emailC.text.trim(),
                          password: passC.text,
                          childName: nameC.text.trim(),
                          avatarUrl: avatar,
                        );

                        if (mounted && success) {
                          Navigator.pop(context);
                          _showSuccess(
                              context,
                              lang.currentLanguage == 'ms'
                                  ? "Akaun kanak-kanak berjaya didaftarkan!"
                                  : "Child account successfully registered!");
                        }
                      } catch (e) {
                        // ⭐️ 3. Catch & Display Firebase/Auth Errors
                        if (mounted) {
                          setS(() => isSaving = false);
                          // Clean up the error message string
                          String cleanError =
                              e.toString().replaceAll('Exception: ', '');
                          _showError(context, cleanError);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      lang.translate('create').toLowerCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            )
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AuthService auth,
      ChildProfile child, LanguageService lang) {
    final nameC = TextEditingController(text: child.name);
    final emailC = TextEditingController(text: auth.getChildEmail(child.id));
    final passC = TextEditingController();
    final confC = TextEditingController();
    String avatar = child.avatarUrl ?? _zooAvatars[0];
    bool isSaving = false;
    bool obsP = true;
    bool obsC = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent clicking outside while saving
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: const Color(0xFFF8F9FE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Text(lang.translate('edit_child'),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: Colors.black)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () => _openAvatarPicker(
                      context, lang, (p) => setS(() => avatar = p)),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage(avatar),
                          backgroundColor: Colors.white),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildCardWrapper(
                    title: lang.translate('user_info'),
                    children: [
                      _buildStyledField(
                          controller: nameC,
                          label: lang.translate('new_name'),
                          icon: Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildReadOnlyField(
                          label: lang.translate('login_email'),
                          value: emailC.text,
                          icon: Icons.email_outlined),
                    ]),
                const SizedBox(height: 20),
                _buildCardWrapper(title: lang.translate('security'), children: [
                  Text(lang.translate('leave_pass_empty'),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildPasswordField(lang.translate('new_password'), passC,
                      obsP, () => setS(() => obsP = !obsP)),
                  const SizedBox(height: 15),
                  _buildPasswordField(lang.translate('confirm_new_password'),
                      confC, obsC, () => setS(() => obsC = !obsC)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.translate('cancel'),
                    style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameC.text.trim().isEmpty) {
                        _showError(context, "Name cannot be empty.");
                        return;
                      }

                      if (passC.text.isNotEmpty || confC.text.isNotEmpty) {
                        if (passC.text.length < 8) {
                          _showError(context,
                              "New password must be at least 8 characters.");
                          return;
                        }
                        // Check if passwords match
                        if (passC.text != confC.text) {
                          _showError(
                              context,
                              lang.currentLanguage == 'ms'
                                  ? "Kata laluan tidak sepadan!"
                                  : "Passwords do not match!");
                          return;
                        }
                      }

                      setS(() => isSaving = true);

                      try {
                        // Call the AuthService to update info
                        await auth.editChild(
                            childId: child.id,
                            newName: nameC.text.trim(),
                            newPassword:
                                passC.text.isNotEmpty ? passC.text : null,
                            newAvatarUrl: avatar);

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          setS(() => isSaving = false);
                          _showError(context, "Failed to update child info.");
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      lang.translate('save').toLowerCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toLowerCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
          fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black, size: 18),
        filled: true,
        fillColor:
            const Color(0xFFFAFAFA), // Neutral light gray instead of purple
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildReadOnlyField(
      {required String label, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Flat neutral background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toLowerCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
          fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Colors.black, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18,
            color: Colors.grey.shade400,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _openAvatarPicker(
      BuildContext context, LanguageService lang, Function(String) onPicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Drag handle for that native feel
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(lang.translate('select_avatar').toLowerCase(),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5)),
          const SizedBox(height: 24),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 16),
              itemCount: _zooAvatars.length,
              itemBuilder: (ctx, index) => GestureDetector(
                onTap: () {
                  onPicked(_zooAvatars[index]);
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFF0F0F0), width: 1)),
                  child: ClipOval(
                      child:
                          Image.asset(_zooAvatars[index], fit: BoxFit.cover)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AuthService auth, String id,
      String name, LanguageService lang) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text(lang.translate('remove_child_title'),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w900)),
              content: Text("${lang.translate('remove_child_msg')} ($name)?",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(lang.translate('cancel').toLowerCase(),
                        style: const TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w700))),
                ElevatedButton(
                    onPressed: () {
                      auth.removeChild(id);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFF3B30), // iOS/Insta style Red
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(lang.translate('remove').toLowerCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
            ));
  }
}
