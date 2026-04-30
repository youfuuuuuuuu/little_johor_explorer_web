import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _nameController.text = auth.currentUser?.displayName ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final lang = Provider.of<LanguageService>(context, listen: false);

    final bool canChangePassword =
        auth.currentUser?.role == 'parent' || auth.currentUser?.role == 'admin';

    if (canChangePassword &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang.translate('pass_not_match')),
          backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_nameController.text.trim() != auth.currentUser?.displayName) {
        await auth.updateProfile(newName: _nameController.text.trim());
      }

      // ⭐️ CHANGED: Uses the new variable here
      if (canChangePassword && _passwordController.text.isNotEmpty) {
        await auth.updatePassword(newPassword: _passwordController.text);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(lang.translate('profile_updated')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(lang.translate('profile_update_fail')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBackgroundLayer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE1BEE7),
            Color(0xFFF8F9FE),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);

    // ⭐️ CHANGED: Now checks if the user is a parent OR an admin for the UI
    final bool canChangePassword =
        auth.currentUser?.role == 'parent' || auth.currentUser?.role == 'admin';

    final String? cleanAvatarUrl =
        auth.currentUser?.avatarUrl?.replaceFirst('file:///', '');

    return Scaffold(
      backgroundColor: Colors.white, // Threads-style clean white
      appBar: AppBar(
        title: Text(
            lang
                .translate('edit_profile')
                .toLowerCase(), // Lowercase for modern look
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black,
                letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- Refined Avatar Section ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.black, width: 2), // High-end ring
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFFF5F5F5),
                        backgroundImage: cleanAvatarUrl != null
                            ? AssetImage(cleanAvatarUrl)
                            : null,
                        child: cleanAvatarUrl == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Form Sections ---
                  _buildCardWrapper(
                    title: lang.translate('user_info'),
                    children: [
                      _buildStyledField(
                        controller: _nameController,
                        label: lang.translate('username'),
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        label: lang.translate('email_no_change'),
                        value: auth.currentUser?.email ?? "",
                        icon: Icons.alternate_email_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (canChangePassword)
                    _buildCardWrapper(
                      title: lang.translate('security'),
                      children: [
                        Text(lang.translate('leave_pass_empty').toLowerCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400)),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                            lang.translate('new_password'),
                            _passwordController,
                            _obscurePassword,
                            () => setState(
                                () => _obscurePassword = !_obscurePassword)),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                            lang.translate('confirm_new_password'),
                            _confirmController,
                            _obscureConfirm,
                            () => setState(
                                () => _obscureConfirm = !_obscureConfirm)),
                      ],
                    ),

                  if (!canChangePassword)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        lang.currentLanguage == 'ms'
                            ? "* akaun kanak-kanak tidak boleh menukar kata laluan."
                            : "* children cannot change their own passwords.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // --- Primary Action Pill ---
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Solid Black action
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(lang.translate('save_changes').toLowerCase(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
        border:
            Border.all(color: const Color(0xFFF0F0F0), width: 1), // Flat border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toLowerCase(),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                  letterSpacing: -0.2)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStyledField(
      {required TextEditingController controller,
      required String label,
      required IconData icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black, size: 18),
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

  Widget _buildReadOnlyField(
      {required String label, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toLowerCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w600)),
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Colors.black, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 18),
          onPressed: onToggle,
          color: Colors.grey.shade400,
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
}
