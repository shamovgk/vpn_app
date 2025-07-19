import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with AutomaticKeepAliveClientMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final normalizedEmail = _emailController.text.trim().toLowerCase();

    await auth.register(
      _usernameController.text.trim(),
      normalizedEmail,
      _passwordController.text,
    );

    if (!mounted) return;

    if (auth.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Регистрация прошла успешно, проверьте email для верификации'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            username: _usernameController.text.trim(),
            email: normalizedEmail,
          ),
        ),
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

  void _navigateToLogin() {
    Navigator.pop(context);
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
                    Icon(Icons.person_add, size: 50, color: theme.primaryColor),
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
                        _emailController.value = _emailController.value.copyWith(
                          text: value.toLowerCase(),
                          selection: TextSelection.collapsed(offset: value.length),
                        );
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
                        if (value.length < 6) return 'Пароль должен содержать минимум 6 символов';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: authProviderValue.isLoading ? null : _register,
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
      ),
    );
  }
}
