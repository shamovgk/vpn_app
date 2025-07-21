import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/features/vpn/widgets/animation_button.dart';
import 'package:vpn_app/features/vpn/widgets/vpn_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../../payments/screens/payment_screen.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/widgets/themed_background.dart';

class VpnScreen extends ConsumerWidget {
  const VpnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final vpnState = ref.watch(vpnProvider);
    final vpnNotifier = ref.read(vpnProvider.notifier);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);

    // Проверка доступа
    bool isAllowed = false;
    if (user != null) {
      final maxDevices = user.subscriptionLevel == 1 ? 6 : 3;
      if (user.trialEndDate != null) {
        final trialEnd = DateTime.tryParse(user.trialEndDate!);
        isAllowed = user.isPaid || (!user.isPaid && trialEnd != null && trialEnd.isAfter(DateTime.now()));
      } else {
        isAllowed = user.isPaid && user.deviceCount < maxDevices;
      }
    }

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'UgbuganVPN',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 20,
              color: colors.text,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.payment, color: colors.textMuted),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              ),
              tooltip: 'Подписка',
            ),
          ],
        ),
        drawer: VpnDrawer(username: user?.username),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimationButton(
                isConnected: vpnState.isConnected,
                isConnecting: vpnState.isConnecting,
                onConnect: isAllowed
                    ? () async {
                        if (vpnState.isConnected) {
                          await vpnNotifier.disconnect();
                        } else if (user != null) {
                          await vpnNotifier.connect(
                            isPaid: user.isPaid,
                            trialEndDate: user.trialEndDate,
                            deviceCount: user.deviceCount,
                            subscriptionLevel: user.subscriptionLevel,
                          );
                        }
                      }
                    : null,
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
