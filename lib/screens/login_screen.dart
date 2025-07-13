import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/vpn_screen.dart';
import 'package:vpn_app/screens/register_screen.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vpn_app/screens/reset_password_screen.dart';

final logger = Logger();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _showForgotPassword = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.login(_usernameController.text, _passwordController.text);
      if (!mounted) return;

      setState(() {
        _failedAttempts = 0;
        _showForgotPassword = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const VpnScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _failedAttempts++;
      logger.i('Login error: $e');
      if (_failedAttempts == 1 && (e.toString().contains('Неверный пароль') || e.toString().contains('Invalid password') || e.toString().contains('401'))) {
        setState(() => _showForgotPassword = true);
      }

      final customColors = Theme.of(context).extension<CustomColors>()!;
      if (e.toString().contains('Логин и пароль обязательны')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Логин и пароль обязательны'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Пользователь не найден')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Пользователь не найден'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Неверный пароль') || e.toString().contains('Invalid password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Неверный логин или пароль'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Срок действия пробного периода истёк')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Срок действия пробного периода истёк, требуется оплата'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Не удалось обновить токен авторизации')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось обновить токен авторизации'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Внутренняя ошибка сервера')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка сервера, попробуйте позже'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Произошла неизвестная ошибка'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      final customColors = Theme.of(context).extension<CustomColors>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Введите логин для восстановления'),
          backgroundColor: customColors?.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AuthProvider.baseUrl}/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          final customColors = Theme.of(context).extension<CustomColors>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Инструкции по восстановлению отправлены на ваш email'),
              backgroundColor: customColors?.info,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen(username: username)),
        );
      } else {
        throw Exception('Ошибка отправки: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      final customColors = Theme.of(context).extension<CustomColors>()!;
      if (e.toString().contains('Пользователь с таким логином не найден')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Пользователь с таким логином не найден'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Не удалось сгенерировать код восстановления')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось сгенерировать код восстановления'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Не удалось отправить email с инструкциями')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось отправить email с инструкциями'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Произошла ошибка при запросе восстановления'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      logger.e('Reset password error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.7,
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
                    if (_showForgotPassword)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: Text(
                            'Забыли пароль?',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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