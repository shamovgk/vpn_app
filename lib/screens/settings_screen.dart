import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/auth_provider.dart';
import 'vpn_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DeviceProvider>().fetchDevices());
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

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
            if (authProvider.isLoggedIn)
              IconButton(
                icon: Icon(Icons.logout, color: theme.textTheme.bodyMedium?.color),
                onPressed: () async {
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                tooltip: 'Выйти',
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: deviceProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : deviceProvider.error != null
                  ? Center(child: Text('Ошибка: ${deviceProvider.error}'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Статус оплаты: ${user?.isPaid == true ? 'Оплачено' : 'Не оплачено'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Уровень подписки: ${user?.subscriptionLevel == 1 ? 'Plus (до 6 устройств)' : 'Basic (до 3 устройств)'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Срок действия подписки: ${user?.trialEndDate != null ? 'До ${user?.trialEndDate}' : 'Не ограничен'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Подключённые устройства (${deviceProvider.devices.length}):',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: deviceProvider.devices.length,
                            itemBuilder: (context, index) {
                              final device = deviceProvider.devices[index];
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
                                    try {
                                      await deviceProvider.removeDevice(device.id);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Устройство успешно удалено')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ошибка: $e')),
                                      );
                                    }
                                  },
                                  tooltip: 'Удалить устройство',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
