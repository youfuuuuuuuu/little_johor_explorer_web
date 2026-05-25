import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  /// Pre-fill the email if coming from login screen
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.sendPasswordReset(email);
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0A0A0A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child:
                  _emailSent ? _buildSuccessView(lang) : _buildFormView(lang),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form view ─────────────────────────────────────────────────────────────
  Widget _buildFormView(LanguageService lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          lang.currentLanguage == 'ms'
              ? 'Tetapkan Semula Kata Laluan'
              : 'Reset Password',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lang.currentLanguage == 'ms'
              ? 'Masukkan alamat e-mel anda. Kami akan menghantar pautan untuk menetapkan semula kata laluan anda.'
              : 'Enter your email address. We\'ll send you a link to reset your password.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Email field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: widget.initialEmail == null,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0A0A0A)),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.alternate_email_rounded,
                  color: Colors.grey.shade400, size: 18),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Send button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    lang.currentLanguage == 'ms'
                        ? 'Hantar Pautan'
                        : 'Send Reset Link',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Success view ──────────────────────────────────────────────────────────
  Widget _buildSuccessView(LanguageService lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Success icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: Color(0xFF22C55E), size: 36),
        ),
        const SizedBox(height: 24),

        Text(
          lang.currentLanguage == 'ms' ? 'E-mel Dihantar!' : 'Email Sent!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          lang.currentLanguage == 'ms'
              ? 'Kami telah menghantar pautan tetapan semula kata laluan ke\n${_emailController.text.trim()}\n\nSila semak peti masuk anda.'
              : 'We\'ve sent a password reset link to\n${_emailController.text.trim()}\n\nPlease check your inbox.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Back to login
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              lang.currentLanguage == 'ms'
                  ? 'Kembali ke Log Masuk'
                  : 'Back to Login',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Resend
        TextButton(
          onPressed:
              _isLoading ? null : () => setState(() => _emailSent = false),
          child: Text(
            lang.currentLanguage == 'ms'
                ? 'Hantar semula e-mel'
                : 'Resend email',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
