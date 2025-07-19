import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final deviceState = ref.watch(deviceProvider);

    final user = authState.user;

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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Настройки',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyMedium?.color),
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
                icon: Icon(Icons.logout, color: theme.textTheme.bodyMedium?.color),
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
                  ? Center(child: Text('Ошибка: ${deviceState.error}'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: user == null
                                ? const Text("Пользователь не найден")
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Статус оплаты: ${user.isPaid ? 'Оплачено' : 'Не оплачено'}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Уровень подписки: ${user.subscriptionLevel == 1 ? 'Plus (до 6 устройств)' : 'Basic (до 3 устройств)'}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Срок действия подписки: ${user.trialEndDate != null ? 'До ${user.trialEndDate}' : 'Не ограничен'}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Text(
                          'Подключённые устройства (${deviceState.devices.length}):',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async =>
                                await ref.read(deviceProvider.notifier).fetchDevices(),
                            child: deviceState.devices.isEmpty
                                ? const Center(child: Text('Нет устройств'))
                                : ListView.separated(
                                    itemCount: deviceState.devices.length,
                                    separatorBuilder: (context, i) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final device = deviceState.devices[index];
                                      return ListTile(
                                        title: Text(
                                          'Устройство ${index + 1} (${device.deviceToken.substring(0, 8)}...)',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        subtitle: Text(
                                          '${device.deviceModel} (${device.deviceOS})\nПоследнее подключение: ${device.lastSeen}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () async {
                                            await ref.read(deviceProvider.notifier).removeDevice(device.id);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Устройство успешно удалено')),
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
