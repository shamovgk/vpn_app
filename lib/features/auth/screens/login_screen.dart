import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import 'package:vpn_app/ui/widgets/app_snackbar_helper.dart';
import '../providers/auth_provider.dart';
import '../../vpn/screens/vpn_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = ref.read(authProvider);

    if (!_formKey.currentState!.validate()) return;

    await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (auth.isLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const VpnScreen()),
        (route) => false,
      );
    } else if (auth.errorMessage != null) {
      _showErrorSnackbar(auth.errorMessage!);
    }
  }

  void _showErrorSnackbar(String message) {
    showAppSnackbar(
      context,
      text: message,
      type: AppSnackbarType.error,
    );
  }

  void _resetPasswordFlow() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showErrorSnackbar('Введите логин для восстановления');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResetPasswordScreen(username: username)),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authProviderValue = ref.watch(authProvider);
    final user = authProviderValue.user;

    return ThemedBackground(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppCustomAppBar(
            title: 'Вход',
            leading: null,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 50, color: colors.primary),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, color: colors.textMuted),
                        labelStyle: TextStyle(color: colors.textMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите логин';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock, color: colors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: colors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        labelStyle: TextStyle(color: colors.textMuted),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите пароль';
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPasswordFlow,
                          child: Text(
                            'Забыли пароль?',
                            style: TextStyle(color: colors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (user != null)
                      Text(
                        'Устройства: ${user.deviceCount}/3',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    if (authProviderValue.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: authProviderValue.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.bgLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Войти',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.bgLight),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _navigateToRegister,
                      child: Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
