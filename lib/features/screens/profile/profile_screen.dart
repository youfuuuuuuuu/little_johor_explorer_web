import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/features/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  void _showAvatarPicker(
      BuildContext context, AuthService auth, LanguageService lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.translate('select_avatar'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black)),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                  ),
                  itemCount: _zooAvatars.length,
                  itemBuilder: (context, index) {
                    final avatarPath = _zooAvatars[index];
                    return GestureDetector(
                      onTap: () async {
                        await auth.updateAvatar(avatarPath);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.purple.withOpacity(0.3), width: 2),
                        ),
                        child: ClipOval(
                            child: Image.asset(avatarPath, fit: BoxFit.cover)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);

    final String? userRole = auth.currentUser?.role;
    final bool isParent = userRole == 'parent';
    final bool isAdmin = userRole == 'admin';

    String roleLabel;
    if (isAdmin) {
      roleLabel = "Admin";
    } else if (isParent) {
      roleLabel = lang.currentLanguage == 'ms' ? "Ibu Bapa" : "Parent";
    } else {
      roleLabel = lang.currentLanguage == 'ms' ? "Kanak-kanak" : "Child";
    }

    Color badgeColor;
    if (isAdmin) {
      badgeColor = Colors.purple.shade500;
    } else if (isParent) {
      badgeColor = Colors.lightBlue.shade400;
    } else {
      badgeColor = Colors.orange.shade400;
    }

    final String? cleanAvatarUrl =
        auth.currentUser?.avatarUrl?.replaceFirst('file:///', '');

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
                  const Color(0xFFF8F9FE),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.purple.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: cleanAvatarUrl != null
                                  ? AssetImage(cleanAvatarUrl)
                                  : null,
                              child: cleanAvatarUrl == null
                                  ? Icon(Icons.person,
                                      size: 60, color: Colors.black)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _showAvatarPicker(context, auth, lang),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(auth.currentUser?.displayName ?? "User",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: badgeColor, // ⭐️ Update this line!
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5)
                            ]),
                        child: Text(roleLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      const SizedBox(height: 50),
                      _buildProfileCard(
                        icon: Icons.edit_rounded,
                        title: lang.translate('edit_profile'),
                        color: Colors.purple.shade400,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfileScreen())),
                      ),
                      const SizedBox(height: 16),
                      _buildProfileCard(
                        icon: Icons.logout_rounded,
                        title: lang.translate('logout'),
                        color: Colors.orange.shade700,
                        onTap: () => _showLogoutDialog(context, auth, lang),
                      ),
                      const SizedBox(height: 16),
                      if (isParent)
                        _buildProfileCard(
                          icon: Icons.person_remove_rounded,
                          title: lang.currentLanguage == 'ms'
                              ? "Padam Akaun"
                              : "Terminate Account",
                          color: Colors.redAccent,
                          onTap: () =>
                              _showDeleteAccountDialog(context, auth, lang),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context, AuthService auth, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lang.translate('logout'),
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        content: Text(lang.translate('logout_confirm_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'))),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text(lang.translate('logout'),
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, AuthService auth, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
            lang.currentLanguage == 'ms'
                ? 'Padam Akaun?'
                : 'Terminate Account?',
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: Colors.redAccent)),
        content: Text(lang.currentLanguage == 'ms'
            ? 'Adakah anda pasti mahu memadam akaun anda secara kekal?'
            : 'Are you sure you want to permanently delete your account?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'))),
          TextButton(
            onPressed: () async {
              await auth.deleteAccount();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text(lang.translate('remove'),
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
