import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/screens/payment_screen.dart';
import '../../devices/screens/settings_screen.dart';
import '../../about/screens/about_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../../ui/theme/theme_provider.dart';
import '../../../ui/theme/app_colors.dart';

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

    return Drawer(
      backgroundColor: colors.bg,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 48, color: colors.text),
                const SizedBox(height: 12),
                Text(
                  user?.username ?? "Гость",
                  style: theme.textTheme.headlineSmall?.copyWith(color: colors.text),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.vpn_key, color: colors.primary),
            title: Text('Подписаться', style: TextStyle(color: colors.text)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.devices, color: colors.info),
            title: Text('Устройства и настройки', style: TextStyle(color: colors.text)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
          // -------- Кнопка смены темы --------
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
          // ----------- Кнопка "Выйти" -----------
          const Spacer(),
          if (auth.isLoggedIn)
            ListTile(
              leading: Icon(Icons.logout, color: colors.danger),
              title: Text('Выйти', style: TextStyle(color: colors.text)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
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
