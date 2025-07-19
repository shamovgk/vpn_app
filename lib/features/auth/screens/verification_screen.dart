import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
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
    final theme = Theme.of(context);
    final authProviderValue = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        color: HSLColor.fromAHSL(1.0, 40, 0.6, 0.08).toColor(),
        image: const DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.3,
          alignment: Alignment(0, 0.1),
        ),
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Верификация Email',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyMedium?.color),
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
                    Icon(Icons.verified_user, size: 100, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 40),
                    Text(
                      'Введите код, отправленный на ${widget.email}',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _verificationCodeController,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Код верификации',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.verified),
                        labelStyle: theme.textTheme.bodyMedium,
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
                        backgroundColor: theme.scaffoldBackgroundColor,
                        foregroundColor: theme.scaffoldBackgroundColor,
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
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
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
