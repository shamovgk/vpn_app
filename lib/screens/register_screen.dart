import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with WidgetsBindingObserver {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllersAndFocus();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeControllersAndFocus() {
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _focusNodes = [FocusNode(), FocusNode(), FocusNode()];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes[0].canRequestFocus) FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {
        logger.i('App resumed, reinitializing controllers and focus');
        _disposeCurrentControllersAndFocus();
        _initializeControllersAndFocus(); 
      });
    }
  }

  void _disposeCurrentControllersAndFocus() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        authProvider.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );
      } catch (e) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), duration: const Duration(seconds: 2)),
          );
          _formKey.currentState!.reset();
        });
        if (_focusNodes[0].canRequestFocus) FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    } else {
      if (_focusNodes[0].canRequestFocus) FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 100, color: Color(0xFF719EA6)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  focusNode: _focusNodes[0],
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите логин';
                    return null;
                  },
                  onTap: () => FocusScope.of(context).requestFocus(_focusNodes[0]),
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusNodes[1]),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  focusNode: _focusNodes[1],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Неверный формат email';
                    return null;
                  },
                  onTap: () => FocusScope.of(context).requestFocus(_focusNodes[1]),
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusNodes[2]),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _focusNodes[2],
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите пароль';
                    if (value.length < 6) return 'Пароль должен содержать минимум 6 символов';
                    return null;
                  },
                  onTap: () => FocusScope.of(context).requestFocus(_focusNodes[2]),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF719EA6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    'Уже есть аккаунт? Войти',
                    style: TextStyle(color: Color(0xFF719EA6)),
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