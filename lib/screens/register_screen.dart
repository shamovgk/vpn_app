import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with AutomaticKeepAliveClientMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController.text = authProvider.username ?? '';
    _emailController.text = authProvider.email ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );
        authProvider.setRegistrationData(_usernameController.text, _emailController.text);
        if (!mounted) return;
        final customColors = Theme.of(context).extension<CustomColors>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Регистрация прошла успешно, проверьте email для верификации'),
            backgroundColor: customColors?.success ?? Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              username: _usernameController.text,
              email: _emailController.text,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        logger.e('Registration error: $e');
        String message = e.toString().replaceFirst('Exception: ', '');
        final customColors = Theme.of(context).extension<CustomColors>();
        if (e.toString().contains('Пользователь с таким email уже существует') || e.toString().contains('duplicate email')) {
          message = 'Пользователь с таким email уже существует, выберите другой';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: customColors?.warning ?? Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (e.toString().contains('Внутренняя ошибка сервера') || e.toString().contains('500')) {
          message = 'Ошибка сервера, попробуйте позже';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Произошла ошибка при регистрации'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLogin() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setRegistrationData(_usernameController.text, _emailController.text);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Регистрация',
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
                  Icon(Icons.person_add, size: 50, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      labelText: 'Логин',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите логин';
                      return null;
                    },
                    onChanged: (value) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      authProvider.setRegistrationData(value, _emailController.text);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Неверный формат email';
                      return null;
                    },
                    onChanged: (value) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      authProvider.setRegistrationData(_usernameController.text, value);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите пароль';
                      if (value.length < 6) return 'Пароль должен содержать минимум 6 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      foregroundColor: theme.scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Зарегистрироваться',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text(
                      'Уже есть аккаунт? Войти',
                      style: TextStyle(color: Theme.of(context).primaryColor),
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