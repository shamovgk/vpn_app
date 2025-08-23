// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/extensions/nav_ext.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/widgets/atoms/ghost_button.dart';
import 'package:vpn_app/ui/widgets/atoms/secondary_button.dart';

import 'package:vpn_app/features/auth/providers/auth_providers.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with AutomaticKeepAliveClientMixin {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pwdNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _pwdNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _username.text.trim();
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;

    await ref.read(authControllerProvider.notifier).register(username, email, password);

    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    final err = state.errorMessage;
    if (err != null) {
      showAppSnackbar(context, text: err, type: AppSnackbarType.error);
    } else {
      showAppSnackbar(context, text: 'Регистрация прошла успешно, проверьте email для верификации', type: AppSnackbarType.success);
      context.goVerify(u: username, e: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.colors;
    final t = context.tokens;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Регистрация',
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textMuted),
        onPressed: () => context.pop(),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Icon(Icons.person_add, size: t.icons.xl, color: c.primary),
            SizedBox(height: t.spacing.lg),
            UsernameField(controller: _username, onSubmitted: (_) => FocusScope.of(context).nextFocus()),
            SizedBox(height: t.spacing.sm),
            EmailField(controller: _email, onSubmitted: (_) => _pwdNode.requestFocus()),
            SizedBox(height: t.spacing.sm),
            PasswordField(controller: _password, focusNode: _pwdNode),
            SizedBox(height: t.spacing.lg + t.spacing.xs),
            SecondaryButton(
              label: 'Зарегистрироваться',
              onPressed: isLoading ? null : _submit,
              icon: isLoading ? null : Icons.person_add,
            ),
            SizedBox(height: t.spacing.md),
            GhostButton(
              label: 'Уже есть аккаунт? Войти',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

