import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/features/auth/providers/access_provider.dart';
import 'package:vpn_app/features/vpn/widgets/animation_button.dart';
import 'package:vpn_app/features/vpn/widgets/vpn_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/widgets/themed_background.dart';
import '../../../ui/widgets/app_custom_appbar.dart';
import '../../payments/widgets/subscription_banner.dart';

class VpnScreen extends ConsumerWidget {
  const VpnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final vpnState = ref.watch(vpnProvider);
    final vpnNotifier = ref.read(vpnProvider.notifier);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isAllowed = ref.watch(vpnAccessProvider);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppCustomAppBar(
          title: 'UgbuganVPN',
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: colors.text),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: VpnDrawer(username: user?.username),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SubscriptionBanner(),
              if (isAllowed)
                AnimationButton(
                  isConnected: vpnState.isConnected,
                  isConnecting: vpnState.isConnecting,
                  onConnect: () async {
                    if (vpnState.isConnected) {
                      await vpnNotifier.disconnect();
                    } else {
                      await vpnNotifier.connect();
                    }
                  },
                ),
              if (vpnState.error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    vpnState.error!,
                    style: TextStyle(
                      color: colors.danger,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
