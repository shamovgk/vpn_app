import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/screens/payment_screen.dart';
import '../../devices/screens/settings_screen.dart';
import '../../about/screens/about_screen.dart';
import '../../auth/screens/login_screen.dart';

class VpnDrawer extends ConsumerWidget {
  final String? username;

  const VpnDrawer({super.key, this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 48),
                const SizedBox(height: 12),
                Text(
                  user?.username ?? "Гость",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Подписаться'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Устройства и настройки'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const Spacer(),
          if (auth.isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Выйти'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                // После выхода перебросить на логин-экран
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
