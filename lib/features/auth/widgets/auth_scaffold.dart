// lib/features/auth/widgets/auth_scaffold.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/ui/widgets/themed_scaffold.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool canPop;
  final Widget? leading;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.body,
    this.canPop = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return ThemedScaffold(
      appBar: AppCustomAppBar(title: title, leading: leading),
      body: PopScope(
        canPop: canPop,
        child: Center(
          child: SingleChildScrollView(
            padding: t.spacing.all(t.spacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

