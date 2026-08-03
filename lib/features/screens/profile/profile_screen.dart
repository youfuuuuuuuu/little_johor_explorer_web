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
    'assets/images/avatars/malayan_tiger.webp',
    'assets/images/avatars/saltwater_crocodile.webp',
    'assets/images/avatars/wallaby.webp',
    'assets/images/avatars/greater_flamingo.webp',
    'assets/images/avatars/malayan_tapir.webp',
    'assets/images/avatars/capybara.webp',
    'assets/images/avatars/sun_bear.webp',
    'assets/images/avatars/mandrill.webp',
  ];

  void _showAvatarPicker(
      BuildContext context, AuthService auth, LanguageService lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.translate('select_avatar'),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A))),
            const SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _zooAvatars.length,
                itemBuilder: (context, index) {
                  final path = _zooAvatars[index];
                  final isCurrent = auth.currentUser?.avatarUrl == path;
                  return GestureDetector(
                    onTap: () async {
                      await auth.updateAvatar(path);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF0A0A0A)
                              : const Color(0xFFF0F0F0),
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child:
                          ClipOval(child: Image.asset(path, fit: BoxFit.cover)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);

    final String? userRole = auth.currentUser?.role;
    final bool isParent = userRole == 'parent';
    final bool isAdmin = userRole == 'admin';
    final String? cleanAvatarUrl =
        auth.currentUser?.avatarUrl?.replaceFirst('file:///', '');

    String roleLabel;
    if (isAdmin) {
      roleLabel = "Admin";
    } else if (isParent) {
      roleLabel = lang.currentLanguage == 'ms' ? "Ibu Bapa" : "Parent";
    } else {
      roleLabel = lang.currentLanguage == 'ms' ? "Kanak-kanak" : "Child";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  lang.translate('my_profile'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFFF0F0F0),
                            backgroundImage: cleanAvatarUrl != null
                                ? AssetImage(cleanAvatarUrl)
                                : null,
                            child: cleanAvatarUrl == null
                                ? const Icon(Icons.person,
                                    size: 36, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _showAvatarPicker(context, auth, lang),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0A0A0A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.displayName ?? "User",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A0A0A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              auth.currentUser?.email ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.person_outline_rounded,
                        label: lang.translate('edit_profile'),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen())),
                      ),
                      _divider(),
                      _menuItem(
                        icon: Icons.logout_rounded,
                        label: lang.translate('logout'),
                        onTap: () => _showLogoutDialog(context, auth, lang),
                        isDestructive: false,
                      ),
                      if (isParent) ...[
                        _divider(),
                        _menuItem(
                          icon: Icons.person_remove_outlined,
                          label: lang.currentLanguage == 'ms'
                              ? "Padam Akaun"
                              : "Terminate Account",
                          onTap: () =>
                              _showDeleteAccountDialog(context, auth, lang),
                          isDestructive: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    Text(
                      'Little Johor Explorer',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : const Color(0xFF0A0A0A);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(height: 0.5, color: const Color(0xFFF0F0F0)),
      );

  void _showLogoutDialog(
      BuildContext context, AuthService auth, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(lang.translate('logout'),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0A0A0A))),
        content: Text(lang.translate('logout_confirm_msg'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'),
                  style: TextStyle(color: Colors.grey.shade500))),
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
                    color: Color(0xFF0A0A0A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, AuthService auth, LanguageService lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
            lang.currentLanguage == 'ms'
                ? 'Padam Akaun?'
                : 'Terminate Account?',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.redAccent)),
        content: Text(
            lang.currentLanguage == 'ms'
                ? 'Adakah anda pasti mahu memadam akaun anda secara kekal?'
                : 'Are you sure you want to permanently delete your account? This cannot be undone.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.translate('cancel'),
                  style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              );

              try {
                await auth.deleteAccount();

                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang.currentLanguage == 'ms'
                            ? 'Akaun berjaya dipadam secara kekal.'
                            : 'Account successfully terminated.',
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );

                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang.currentLanguage == 'ms'
                            ? 'Ralat: Sila log keluar dan log masuk semula untuk memadam akaun.'
                            : 'Error: Please logout and login again to delete your account.',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(lang.translate('remove'),
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
