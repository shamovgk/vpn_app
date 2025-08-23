// lib/features/auth/screens/gate_screen.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/ui/widgets/themed_scaffold.dart';

class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return ThemedScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: t.icons.xl, color: c.primary),
            SizedBox(height: t.spacing.sm),
            CircularProgressIndicator(color: c.primary),
            SizedBox(height: t.spacing.xs),
            Text('Проверяем сессию...', style: t.typography.body.copyWith(color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}

