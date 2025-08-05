import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../devices/screens/device_screen.dart';
import '../../about/screens/about_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../../ui/theme/theme_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../main.dart';
import '../../payments/screens/subscription_screen.dart';

class VpnDrawer extends ConsumerWidget {
  final String? username;

  const VpnDrawer({super.key, this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);
    final themeNotifier = ref.read(themeProvider);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            offset: const Offset(8, 0),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Drawer(
        backgroundColor: colors.bg,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 32, bottom: 24),
              decoration: BoxDecoration(
                color: colors.bg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.account_circle, size: 48, color: colors.text),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.username ?? "Гость",
                    style: theme.textTheme.headlineSmall?.copyWith(color: colors.text),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.diamond_rounded, color: colors.primary),
              title: Text('Подписка', style: TextStyle(color: colors.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.devices, color: colors.info),
              title: Text('Устройства', style: TextStyle(color: colors.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevicesScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: colors.secondary),
              title: Text('О приложении', style: TextStyle(color: colors.text)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: Icon(Icons.brightness_6, color: colors.highlight),
              title: Text('Сменить тему', style: TextStyle(color: colors.text)),
              onTap: () {
                ref.read(themeProvider).toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Тема изменена на ${themeNotifier.themeMode == ThemeMode.dark ? 'Тёмную' : 'Светлую'}',
                      style: TextStyle(color: colors.text),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: colors.bgLight,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            if (auth.isLoggedIn)
              ListTile(
                leading: Icon(Icons.logout, color: colors.danger),
                title: Text('Выйти', style: TextStyle(color: colors.text)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
