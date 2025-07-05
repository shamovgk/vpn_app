import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';
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
  bool get wantKeepAlive => true; // Сохраняем состояние

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
      }
    } catch (e) {
      logger.e('Error canceling registration: $e');
    }
  }

  void _verifyEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.verifyEmail(widget.username, widget.email, _verificationCodeController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! You can now log in.')),
        );
        authProvider.resetRegistrationData();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        logger.e('Verification error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка верификации: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() async {
    setState(() => _isLoading = true);
    await _cancelRegistration(); // Отменяем регистрацию на сервере
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.resetRegistrationData(); // Сбрасываем данные
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
    return PopScope(
      canPop: false, 
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Email Verification',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20)),

          leading: IconButton(
            icon: Icon(Icons.arrow_back,color: theme.textTheme.bodyMedium?.color),
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
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.verified),
                      labelStyle: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}