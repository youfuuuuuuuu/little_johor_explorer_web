import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/core/constants/routes.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';
import 'package:little_johor_explorer/core/widgets/custom_button.dart';
import 'package:little_johor_explorer/core/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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

  String _selectedAvatar = 'assets/images/avatars/malayan_tiger.png';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final storageService =
            Provider.of<LocalStorageService>(context, listen: false);

        final success = await authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          role: 'parent',
          avatarUrl: _selectedAvatar,
        );

        if (success && mounted) {
          storageService.clearUserSession();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Registration successful! Please log in.'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Registration failed: Email already registered!'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, const Color(0xFFF8F9FE)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Pick Your Avatar!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: _zooAvatars.length,
                        itemBuilder: (context, index) {
                          final avatarPath = _zooAvatars[index];
                          bool isSelected = _selectedAvatar == avatarPath;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedAvatar = avatarPath),
                            child: AnimatedScale(
                              scale: isSelected ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.orange
                                        : Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.orange.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(avatarPath,
                                      fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _displayNameController,
                          labelText: 'Explorer Name',
                          prefixIcon: const Icon(Icons.face_rounded,
                              color: Colors.deepPurple),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.alternate_email_rounded,
                              color: Colors.deepPurple),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Email is required';
                            if (!value.contains('@'))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_open_rounded,
                              color: Colors.deepPurple),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 8)
                                  ? 'Too short'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          obscureText: _obscureConfirm,
                          prefixIcon: const Icon(Icons.verified_user_rounded,
                              color: Colors.deepPurple),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text)
                              return 'Mismatch';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          width: double.infinity,
                          height: 55,
                          child: CustomButton(
                            text: 'GET STARTED!',
                            onPressed: _handleRegister,
                          ),
                        ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 14),
                        children: [
                          const TextSpan(text: "Already an Explorer? "),
                          TextSpan(
                            text: "Log In",
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
