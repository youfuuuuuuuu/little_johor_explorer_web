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

    // ⭐️ CHANGED: Now checks if the user is a parent OR an admin
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
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(lang.translate('edit_profile'),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          _buildBackgroundLayer(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
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
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: cleanAvatarUrl != null
                              ? AssetImage(cleanAvatarUrl)
                              : null,
                          child: cleanAvatarUrl == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Color(0xFFE1BEE7))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildCardWrapper(
                        title: lang.translate('user_info'),
                        children: [
                          _buildStyledField(
                            controller: _nameController,
                            label: lang.translate('username'),
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildReadOnlyField(
                            label: lang.translate('email_no_change'),
                            value: auth.currentUser?.email ?? "",
                            icon: Icons.email_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ⭐️ CHANGED: Show the password card if they are parent OR admin
                      if (canChangePassword)
                        _buildCardWrapper(
                          title: lang.translate('security'),
                          children: [
                            Text(lang.translate('leave_pass_empty'),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey.shade400)),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                                lang.translate('new_password'),
                                _passwordController,
                                _obscurePassword,
                                () => setState(() =>
                                    _obscurePassword = !_obscurePassword)),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                                lang.translate('confirm_new_password'),
                                _confirmController,
                                _obscureConfirm,
                                () => setState(
                                    () => _obscureConfirm = !_obscureConfirm)),
                          ],
                        ),

                      // ⭐️ CHANGED: Updated the error text for children
                      if (!canChangePassword)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Text(
                            lang.currentLanguage == 'ms'
                                ? "* Akaun kanak-kanak tidak boleh menukar kata laluan."
                                : "* Children cannot change their own passwords.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAB47BC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(lang.translate('save_changes'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900)),
                        ),
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

  Widget _buildCardWrapper(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.purple.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black)),
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
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade400),
        prefixIcon: Icon(icon, color: Colors.black, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
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
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade400),
        prefixIcon:
            const Icon(Icons.lock_rounded, color: Colors.black, size: 20),
        suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                size: 20),
            onPressed: onToggle,
            color: Colors.blueGrey.shade300),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
