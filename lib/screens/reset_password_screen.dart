import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:logger/logger.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/login_screen.dart';

final logger = Logger();

class ResetPasswordScreen extends StatefulWidget {
  final String username;

  const ResetPasswordScreen({super.key, required this.username});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = widget.username.trim();
    final resetCode = _resetCodeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    logger.i('Attempting reset: username=$username, resetCode=$resetCode, newPassword length=${newPassword.length}');

    try {
      await authProvider.resetPassword(username, resetCode, newPassword);
      if (!mounted) return;
      final customColors = Theme.of(context).extension<CustomColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Пароль успешно сброшен'),
          backgroundColor: customColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final customColors = Theme.of(context).extension<CustomColors>()!;
      if (e.toString().contains('Неверный или истёкший код восстановления')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Неверный или истёкший код восстановления'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Все поля обязательны')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Заполните все поля (логин, код и новый пароль)'),
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
      } else if (e.toString().contains('Не удалось обновить пароль')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось обновить пароль'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Произошла ошибка при сбросе пароля'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background_new.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.7,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Сброс пароля',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_reset, size: 50, color: theme.primaryColor),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _resetCodeController,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      labelText: 'Код восстановления',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.verified, color: theme.textTheme.bodyMedium?.color),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите код восстановления';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _newPasswordController,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: theme.textTheme.bodyMedium?.color),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите новый пароль';
                      if (value.length < 6) return 'Пароль должен содержать минимум 6 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: theme.elevatedButtonTheme.style,
                    child: Text(
                      'Сбросить пароль',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
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