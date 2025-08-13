// lib/features/vpn/screens/vpn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/features/subscription/providers/subscription_providers.dart';
import 'package:vpn_app/features/vpn/providers/vpn_providers.dart';
import '../widgets/animation_button.dart';
import '../../../ui/widgets/app_drawer.dart';

import '../../../ui/widgets/app_custom_appbar.dart';
import '../../../ui/widgets/themed_scaffold.dart';
import '../../subscription/widgets/subscription_banner.dart';

class VpnScreen extends ConsumerWidget {
  const VpnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.tokens;

    final vpnState = ref.watch(vpnControllerProvider);
    final vpn = ref.read(vpnControllerProvider.notifier);
    final isAllowed = ref.watch(vpnAccessProvider);

    final isConnected = vpnState is VpnConnected;
    final isBusy = vpnState is VpnConnecting || vpnState is VpnDisconnecting;
    final error = vpnState is VpnError ? vpnState.message : null;

    return ThemedScaffold(
      appBar: AppCustomAppBar(
        title: 'UgbuganVPN',
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: c.text),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SubscriptionBanner(),
            if (isAllowed)
              AnimationButton(
                isConnected: isConnected,
                isConnecting: isBusy,
                onConnect: () async {
                  if (isConnected) {
                    await vpn.disconnectPressed();
                  } else {
                    await vpn.connectPressed();
                  }
                },
              ),
            if (error != null)
              Padding(
                padding: t.spacing.all(t.spacing.md),
                child: Text(
                  error,
                  style: t.typography.body.copyWith(color: c.danger, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

