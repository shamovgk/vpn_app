// lib/features/auth/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/extensions/nav_ext.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/widgets/app_snackbar_helper.dart';
import 'package:vpn_app/ui/widgets/atoms/secondary_button.dart';
import 'package:vpn_app/features/auth/providers/auth_providers.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String username;
  const ResetPasswordScreen({super.key, required this.username});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _pwdNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _code.dispose();
    _newPassword.dispose();
    _pwdNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).resetPassword(
          widget.username.trim(),
          _code.text.trim(),
          _newPassword.text.trim(),
        );

    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    final err = state.errorMessage;
    if (err != null) {
      showAppSnackbar(context, text: err, type: AppSnackbarType.error);
    } else {
      showAppSnackbar(context, text: 'Пароль успешно сброшен', type: AppSnackbarType.success);
      context.goLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Сброс пароля',
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textMuted),
        onPressed: () => context.pop(),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Icon(Icons.lock_reset, size: 50, color: c.primary),
            SizedBox(height: t.spacing.lg + t.spacing.xs),
            CodeField(
              controller: _code,
              label: 'Код восстановления',
              textInputAction: TextInputAction.next,
              exactLength: 6,
              onSubmitted: (_) => _pwdNode.requestFocus(),
            ),
            SizedBox(height: t.spacing.sm),
            PasswordField(
              controller: _newPassword,
              focusNode: _pwdNode,
              label: 'Новый пароль',
            ),
            SizedBox(height: t.spacing.lg + t.spacing.xs),
            SecondaryButton(
              label: 'Сбросить пароль',
              onPressed: isLoading ? null : _submit,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}


