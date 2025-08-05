import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import '../../devices/providers/device_provider.dart';
import '../services/device_id_helper.dart';

final currentDeviceTokenProvider = FutureProvider<String>((ref) async {
  return await getDeviceToken();
});

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceProvider);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    const maxDevices = 3;
    final currentDeviceTokenAsync = ref.watch(currentDeviceTokenProvider);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Устройства',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 20,
                color: colors.text,
              )),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: currentDeviceTokenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка получения deviceToken: $e')),
          data: (currentDeviceToken) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: deviceState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : deviceState.error != null
                    ? Center(child: Text('Ошибка: ${deviceState.error}', style: TextStyle(color: colors.danger)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            color: colors.bgLight,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'Подключено устройств: ${deviceState.devices.length} из $maxDevices',
                                  style: TextStyle(
                                    color: colors.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async =>
                                  await ref.read(deviceProvider.notifier).fetchDevices(),
                              child: deviceState.devices.isEmpty
                                  ? Center(child: Text('Нет устройств', style: TextStyle(color: colors.textMuted)))
                                  : ListView.separated(
                                      itemCount: deviceState.devices.length,
                                      separatorBuilder: (_, __) => Divider(color: colors.borderMuted),
                                      itemBuilder: (context, idx) {
                                        final device = deviceState.devices[idx];
                                        final isCurrentDevice = device.deviceToken == currentDeviceToken;
                                        return ListTile(
                                          leading: Icon(Icons.devices_other, color: colors.primary),
                                          title: Text(
                                            '${device.deviceModel} (${device.deviceOS})',
                                            style: TextStyle(color: colors.text),
                                          ),
                                          subtitle: Text(
                                            'Последнее подключение: ${device.lastSeen}',
                                            style: TextStyle(color: colors.textMuted, fontSize: 14),
                                          ),
                                          trailing: isCurrentDevice
                                              ? Tooltip(
                                                  message: 'Текущее устройство',
                                                  child: Icon(Icons.lock, color: colors.textMuted),
                                                )
                                              : IconButton(
                                                  icon: Icon(Icons.delete, color: colors.danger),
                                                  tooltip: 'Отключить',
                                                  onPressed: () async {
                                                    await ref.read(deviceProvider.notifier).removeDevice(device.deviceToken);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Устройство отключено')),
                                                      );
                                                    }
                                                  },
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
      ),
    );
  }
}
