import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';
import 'package:little_johor_explorer/data/models/user.dart';

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

  Map<String, dynamic> _getRealTimeStats(
      LocalStorageService storage, String? childId) {
    if (childId == null)
      return {'stories': 0, 'quizzes': 0, 'badges': 0, 'screenTimeMins': 0};
    final history = storage.getHistoryForUser(childId);
    int quizCount = history
        .where((item) => item.contains("Quiz:") || item.contains("Earned"))
        .length;
    return {
      'stories': storage.getReadStoryIdsForUser(childId).length,
      'quizzes': quizCount,
      'badges': storage.getEarnedBadgeIdsForUser(childId).length,
      'screenTimeMins': storage.getTotalReadingTimeForUser(childId),
    };
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
    final storage = Provider.of<LocalStorageService>(context);

    final user = auth.currentUser;
    if (user == null || user.role != 'parent' || user is! ParentProfile) {
      return const Scaffold(
          body: Center(child: Text("Loading Parent Data...")));
    }

    final children = user.children;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade100.withOpacity(0.5),
                  const Color(0xFFF8F9FE)
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(children.length, lang, auth),
                Expanded(
                  child: children.isEmpty
                      ? _buildEmptyState(lang)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          itemCount: children.length,
                          itemBuilder: (context, index) => _buildChildCard(
                              children[index],
                              _getRealTimeStats(storage, children[index].id),
                              lang,
                              auth),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, LanguageService lang, AuthService auth) {
    // Access children list from the parent profile to check length
    final user = auth.currentUser as ParentProfile;
    final children = user.children;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.translate('parent_control'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black)),
                Text(
                    "${lang.translate('total_linked_children')}: $count / 5", // Added /5 for clarity
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // ⭐️ INTEGRATED LIMIT CHECK
              if (children.length >= 5) {
                _showError(
                    context,
                    lang.currentLanguage == 'ms'
                        ? "Maksimum 5 akaun kanak-kanak sahaja."
                        : "Maximum 5 children allowed per account.");
              } else {
                _showAddChildDialog(context, auth, lang);
              }
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(lang.translate('add_child'),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAB47BC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildProfile child, Map<String, dynamic> stats,
      LanguageService lang, AuthService auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.purple.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ]),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.purple.shade50,
            backgroundImage: child.avatarUrl != null
                ? AssetImage(child.avatarUrl!.replaceFirst('file:///', ''))
                : null,
            child: child.avatarUrl == null
                ? const Icon(Icons.face_rounded, color: Colors.purple)
                : null),
        title: Text(child.name,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black)),
        subtitle: Text(
            lang.currentLanguage == 'ms' ? "Lihat Aktiviti" : "View Activity",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        children: [
          const Divider(indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _statItem(Icons.auto_stories_rounded, "${stats['stories']}",
                    lang.translate('stories_label'), Colors.blue),
                _statItem(Icons.extension_rounded, "${stats['quizzes']}",
                    lang.translate('quiz'), Colors.orange),
                _statItem(
                    Icons.timer_rounded,
                    _formatScreenTime(stats['screenTimeMins'], lang),
                    lang.translate('time'),
                    Colors.green),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () =>
                            _showEditDialog(context, auth, child, lang),
                        icon: const Icon(Icons.edit_rounded,
                            size: 18, color: Colors.black),
                        label: Text(lang.translate('edit'),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.purple.shade100),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 10),
                IconButton(
                    onPressed: () => _confirmDelete(
                        context, auth, child.id, child.name, lang),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color)),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildEmptyState(LanguageService lang) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.family_restroom_rounded,
          size: 80, color: Colors.purple.withOpacity(0.2)),
      const SizedBox(height: 16),
      Text(lang.translate('no_childs'),
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
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
                  backgroundColor: const Color(0xFFAB47BC),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(lang.translate('create')),
            ),
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
                  backgroundColor: const Color(0xFFAB47BC),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(lang.translate('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.purple.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black)),
        const SizedBox(height: 15),
        ...children,
      ]),
    );
  }

  Widget _buildStyledField(
      {required TextEditingController controller,
      required String label,
      required IconData icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.black, size: 20),
          filled: true,
          fillColor: Colors.purple.shade50.withOpacity(0.3),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  Widget _buildReadOnlyField(
      {required String label, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text(value,
                style: const TextStyle(fontSize: 14, color: Colors.black)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon:
              const Icon(Icons.lock_outline, color: Colors.black, size: 20),
          suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20),
              onPressed: onToggle,
              color: Colors.grey),
          filled: true,
          fillColor: Colors.purple.shade50.withOpacity(0.3),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  void _openAvatarPicker(
      BuildContext context, LanguageService lang, Function(String) onPicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(lang.translate('select_avatar'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black)),
          const SizedBox(height: 20),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 15, crossAxisSpacing: 15),
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
                          Border.all(color: Colors.purple.shade100, width: 2)),
                  child: ClipOval(
                      child:
                          Image.asset(_zooAvatars[index], fit: BoxFit.cover)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AuthService auth, String id,
      String name, LanguageService lang) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(lang.translate('remove_child_title'),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              content: Text("${lang.translate('remove_child_msg')} ($name)",
                  style: const TextStyle(color: Colors.black87)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(lang.translate('cancel'),
                        style: const TextStyle(color: Colors.grey))),
                ElevatedButton(
                    onPressed: () {
                      auth.removeChild(id);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: const StadiumBorder()),
                    child: Text(lang.translate('remove'),
                        style: const TextStyle(color: Colors.white))),
              ],
            ));
  }
}
