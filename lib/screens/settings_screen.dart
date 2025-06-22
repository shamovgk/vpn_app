import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vpnProvider = Provider.of<VpnProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Настройки',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статус авторизации: ${authProvider.isAuthenticated ? 'Авторизован' : 'Не авторизован'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Статус оплаты: ${authProvider.isPaid ? 'Оплачено' : 'Не оплачено'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Статус VPN: ${vpnProvider.isConnected ? 'Подключено' : 'Отключено'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (authProvider.isAuthenticated)
              ElevatedButton(
                onPressed: () async {
                  if (!mounted) return;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    if (vpnProvider.isConnected) {
                      await vpnProvider.disconnect();
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('VPN отключён')),
                      );
                    } else {
                      await vpnProvider.connect();
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('VPN подключён')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                },
                style: Theme.of(context).elevatedButtonTheme.style,
                child: Text(vpnProvider.isConnected ? 'Отключить VPN' : 'Подключить VPN'),
              ),
            const SizedBox(height: 10),
            if (authProvider.isAuthenticated)
              ElevatedButton(
                onPressed: () async {
                  if (!mounted) return;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    await authProvider.logout();
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Выход выполнен')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Ошибка выхода: $e')),
                    );
                  }
                },
                style: Theme.of(context).elevatedButtonTheme.style,
                child: const Text('Выйти'),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              style: Theme.of(context).elevatedButtonTheme.style,
              child: Text('Переключить на ${themeProvider.themeMode == ThemeMode.dark ? 'Светлую' : 'Тёмную'} тему'),
            ),
          ],
        ),
      ),
    );
  }
}