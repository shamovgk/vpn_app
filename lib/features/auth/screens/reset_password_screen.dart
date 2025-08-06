import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/widgets/app_snackbar_helper.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String username;
  const ResetPasswordScreen({super.key, required this.username});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final auth = ref.read(authProvider);

    if (!_formKey.currentState!.validate() || auth.isLoading) return;

    await auth.resetPassword(
      widget.username.trim(),
      _resetCodeController.text.trim(),
      _newPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (auth.errorMessage == null) {
      showAppSnackbar(
        context,
        text: 'Пароль успешно сброшен',
        type: AppSnackbarType.success,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authProviderValue = ref.watch(authProvider);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppCustomAppBar(
          title: 'Сброс пароля',
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textMuted),
            onPressed: () => Navigator.of(context).maybePop(),
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
                  Icon(Icons.lock_reset, size: 50, color: colors.primary),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _resetCodeController,
                    style: TextStyle(color: colors.text),
                    decoration: InputDecoration(
                      labelText: 'Код восстановления',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.verified, color: colors.textMuted),
                      labelStyle: TextStyle(color: colors.textMuted),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите код восстановления';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _newPasswordController,
                    style: TextStyle(color: colors.text),
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: colors.textMuted),
                      labelStyle: TextStyle(color: colors.textMuted),
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
                    onPressed: authProviderValue.isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.bgLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: authProviderValue.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Сбросить пароль',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.bgLight),
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
