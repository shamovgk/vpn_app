import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/vpn_screen.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'package:logger/logger.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.login(_usernameController.text, _passwordController.text);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VpnScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        if (e.toString().contains('Пожалуйста, проверьте email')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Пожалуйста, проверьте email для верификации'),
                duration: const Duration(seconds: 5),
                backgroundColor: Theme.of(context).extension<CustomColors>()!.warning,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 100, color: Theme.of(context).primaryColor),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Логин',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите логин';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите пароль';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _login,
                  style: Theme.of(context).elevatedButtonTheme.style,
                  child: const Text(
                    'Войти',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text(
                    'Зарегистрироваться',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}