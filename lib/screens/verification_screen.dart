import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/login_screen.dart';
import 'package:vpn_app/screens/register_screen.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logger = Logger();

class VerificationScreen extends StatefulWidget {
  final String username;
  final String email;

  const VerificationScreen({super.key, required this.username, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with AutomaticKeepAliveClientMixin {
  final _verificationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _cancelRegistration() async {
    try {
      final response = await http.post(
        Uri.parse('${AuthProvider.baseUrl}/cancel-registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'email': widget.email}),
      );
      if (response.statusCode != 200) {
        logger.e('Failed to cancel registration: ${response.body}');
      } else {
        if (mounted) {
          final customColors = Theme.of(context).extension<CustomColors>()!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Регистрация успешно отменена'),
              backgroundColor: customColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Error canceling registration: $e');
    }
  }

  Future<void> _verifyEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.verifyEmail(widget.username, widget.email, _verificationCodeController.text);
        if (!mounted) return;
        final customColors = Theme.of(context).extension<CustomColors>()!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email верифицирован! Теперь вы можете войти.'),
            backgroundColor: customColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        authProvider.resetRegistrationData();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        logger.e('Verification error: $e');
        final customColors = Theme.of(context).extension<CustomColors>()!;
        if (e.toString().contains('Срок действия кода верификации истёк')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Срок действия кода верификации истёк, запросите новый'),
              backgroundColor: customColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (e.toString().contains('Неверный код верификации')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Введён неверный код верификации'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (e.toString().contains('Пользователь или email не найдены')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Пользователь или email не найдены в ожидающих верификации'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (e.toString().contains('Не удалось завершить верификацию')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось завершить верификацию'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Произошла ошибка при верификации'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    setState(() => _isLoading = true);
    _cancelRegistration();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.resetRegistrationData();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background_new.png'),
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
              'Email Verification',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyMedium?.color),
              onPressed: _navigateToRegister,
            ),
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
                      'Enter the verification code sent to ${widget.email}',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _verificationCodeController,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
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
                      onPressed: _isLoading ? null : _verifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        foregroundColor: theme.scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Verify Email',
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