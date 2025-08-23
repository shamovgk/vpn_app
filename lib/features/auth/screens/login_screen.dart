// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/extensions/nav_ext.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import 'package:vpn_app/features/devices/widgets/device_limit_hint.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/widgets/atoms/ghost_button.dart';
import 'package:vpn_app/ui/widgets/atoms/primary_button.dart';

import 'package:vpn_app/features/auth/providers/auth_providers.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _pwdNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _pwdNode.dispose();
    super.dispose();
  }

Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  final container = ProviderScope.containerOf(context, listen: false);

  await container.read(authControllerProvider.notifier)
      .login(_username.text.trim(), _password.text);

  if (!mounted) return;

  final state = container.read(authControllerProvider);
  final err = state.errorMessage;
  if (err != null) {
    showAppSnackbar(context, text: err, type: AppSnackbarType.error);
  }
}

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Вход',
      canPop: false,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: t.icons.xl, color: c.primary),
            SizedBox(height: t.spacing.lg),
            UsernameField(
              controller: _username,
              onSubmitted: (_) => _pwdNode.requestFocus(),
            ),
            SizedBox(height: t.spacing.sm),
            PasswordField(
              controller: _password,
              focusNode: _pwdNode,
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: t.spacing.xs),
            GhostButton(
              label: 'Забыли пароль?',
              onPressed: () {
                final u = _username.text.trim();
                if (u.isEmpty) {
                  showAppSnackbar(context, text: 'Введите логин для восстановления', type: AppSnackbarType.error);
                  return;
                }
                context.pushReset(u: u);
              },
            ),
            SizedBox(height: t.spacing.sm),
            const DeviceLimitHint(maxDevices: 3),
            SizedBox(height: t.spacing.sm),
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: t.spacing.lg),
                child: const CircularProgressIndicator(),
              ),
            SizedBox(height: t.spacing.sm),
            PrimaryButton(
              label: 'Войти',
              onPressed: isLoading ? null : _submit,
            ),
            SizedBox(height: t.spacing.sm),
            GhostButton(
              label: 'Зарегистрироваться',
              onPressed: () => context.pushRegister(),
            ),
          ],
        ),
      ),
    );
  }
}