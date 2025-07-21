import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/devices/providers/device_provider.dart';
import '../../../../features/vpn/screens/vpn_screen.dart';
import '../../../../features/auth/screens/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(deviceProvider.notifier).fetchDevices());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final deviceState = ref.watch(deviceProvider);

    final user = authState.user;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Настройки',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20, color: colors.text),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textMuted),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VpnScreen()),
              );
            },
          ),
          actions: [
            if (authState.isLoggedIn)
              IconButton(
                icon: Icon(Icons.logout, color: colors.textMuted),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                tooltip: 'Выйти',
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: deviceState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : deviceState.error != null
                  ? Center(child: Text('Ошибка: ${deviceState.error}', style: TextStyle(color: colors.danger)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: colors.bgLight,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: user == null
                                ? Text("Пользователь не найден", style: TextStyle(color: colors.text))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Статус оплаты: ${user.isPaid ? 'Оплачено' : 'Не оплачено'}',
                                        style: TextStyle(color: colors.textMuted),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Уровень подписки: ${user.subscriptionLevel == 1 ? 'Plus (до 6 устройств)' : 'Basic (до 3 устройств)'}',
                                        style: TextStyle(color: colors.textMuted),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Срок действия подписки: ${user.trialEndDate != null ? 'До ${user.trialEndDate}' : 'Не ограничен'}',
                                        style: TextStyle(color: colors.textMuted),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Text(
                          'Подключённые устройства (${deviceState.devices.length}):',
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async =>
                                await ref.read(deviceProvider.notifier).fetchDevices(),
                            child: deviceState.devices.isEmpty
                                ? Center(
                                    child: Text('Нет устройств', style: TextStyle(color: colors.textMuted)),
                                  )
                                : ListView.separated(
                                    itemCount: deviceState.devices.length,
                                    separatorBuilder: (context, i) => Divider(height: 1, color: colors.borderMuted),
                                    itemBuilder: (context, index) {
                                      final device = deviceState.devices[index];
                                      return ListTile(
                                        title: Text(
                                          'Устройство ${index + 1} (${device.deviceToken.substring(0, 8)}...)',
                                          style: TextStyle(color: colors.text),
                                        ),
                                        subtitle: Text(
                                          '${device.deviceModel} (${device.deviceOS})\nПоследнее подключение: ${device.lastSeen}',
                                          style: TextStyle(color: colors.textMuted, fontSize: 14),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete, color: colors.danger),
                                          onPressed: () async {
                                            await ref.read(deviceProvider.notifier).removeDevice(device.id);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Устройство успешно удалено')),
                                            );
                                          },
                                          tooltip: 'Удалить устройство',
                                        ),
                                      );
                                    },
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
