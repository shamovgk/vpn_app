import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String username;
  final String email;

  const VerificationScreen({super.key, required this.username, required this.email});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> with AutomaticKeepAliveClientMixin {
  final _verificationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final auth = ref.read(authProvider);

    if (!_formKey.currentState!.validate()) return;

    await auth.verifyEmail(
      widget.username,
      widget.email,
      _verificationCodeController.text.trim(),
    );

    if (!mounted) return;

    if (auth.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email верифицирован! Теперь вы можете войти.'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _showErrorSnackbar(auth.errorMessage!);
    }
  }

  void _showErrorSnackbar(String message) {
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = AppColors.of(context);
    final authProviderValue = ref.watch(authProvider);

    return ThemedBackground(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Верификация Email',
              style: TextStyle(fontSize: 20, color: colors.text, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textMuted),
              onPressed: _navigateToRegister,
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, size: 100, color: colors.primary),
                    const SizedBox(height: 40),
                    Text(
                      'Введите код, отправленный на ${widget.email}',
                      style: TextStyle(color: colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _verificationCodeController,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        labelText: 'Код верификации',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.verified, color: colors.textMuted),
                        labelStyle: TextStyle(color: colors.textMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите код верификации';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: authProviderValue.isLoading ? null : _verifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.bgLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: authProviderValue.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Подтвердить Email',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.bgLight),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
