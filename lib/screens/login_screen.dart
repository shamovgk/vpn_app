import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/vpn_screen.dart';
import 'package:vpn_app/screens/register_screen.dart';
import 'package:vpn_app/screens/reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      // Успешный вход — переход на VPN-экран
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const VpnScreen()),
        (route) => false,
      );
    } else if (authProvider.errorMessage != null) {
      _showErrorSnackbar(authProvider.errorMessage!);
    }
  }

  void _showErrorSnackbar(String message) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: customColors?.warning ?? theme.colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
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
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
              'Вход',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
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
                    Icon(Icons.lock, size: 50, color: theme.primaryColor),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, color: theme.textTheme.bodyMedium?.color),
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите логин';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock, color: theme.textTheme.bodyMedium?.color),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите пароль';
                        return null;
                      },
                    ),
                    // "Забыли пароль?" — теперь всегда видно
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPasswordFlow,
                          child: Text(
                            'Забыли пароль?',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (user != null)
                      Text(
                        'Устройства: ${user.deviceCount}/${user.subscriptionLevel == 1 ? 6 : 3}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (authProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _login,
                      style: theme.elevatedButtonTheme.style,
                      child: Text(
                        'Войти',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _navigateToRegister,
                      child: Text(
                        'Зарегистрироваться',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
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
