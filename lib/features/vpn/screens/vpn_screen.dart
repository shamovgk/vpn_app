import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/features/vpn/widgets/animation_button.dart';
import 'package:vpn_app/features/vpn/widgets/vpn_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../../payments/screens/payment_screen.dart';

class VpnScreen extends ConsumerWidget {
  const VpnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Container(
      decoration: BoxDecoration(
        color: HSLColor.fromAHSL(1.0, 40, 0.6, 0.08).toColor(),
        image: const DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.3,
          alignment: Alignment(0, 0.1),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('UgbuganVPN'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              ),
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
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
