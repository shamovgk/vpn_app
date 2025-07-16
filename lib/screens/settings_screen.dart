import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/screens/login_screen.dart';
import 'package:vpn_app/screens/vpn_screen.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AuthProvider.baseUrl}/get-devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _devices = data.map((device) => {
            'id': device['id'],
            'device_token': device['device_token'],
            'last_seen': device['last_seen'],
            'device_model': device['device_model'] ?? 'Unknown Model',
            'device_os': device['device_os'] ?? 'Unknown OS',
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load devices: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки устройств: $e')),
      );
    }
  }

  Future<void> _removeDevice(String deviceToken) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.removeDevice(deviceToken);
      await _fetchDevices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Устройство успешно удалено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления устройства: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentDeviceToken = authProvider.deviceToken;

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
      child: PopScope(
        canPop: false,
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
              if (authProvider.isAuthenticated)
                IconButton(
                  icon: Icon(Icons.logout, color: theme.textTheme.bodyMedium?.color),
                  onPressed: () {
                    Navigator.pop(context);
                    authProvider.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  tooltip: 'Выйти',
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статус оплаты: ${authProvider.isPaid ? 'Оплачено' : 'Не оплачено'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Уровень подписки: ${authProvider.subscriptionLevel == 1 ? 'Plus (до 6 устройств)' : 'Basic (до 3 устройств)'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Срок действия подписки: ${authProvider.trialEndDate != null ? 'До ${authProvider.trialEndDate}' : 'Не ограничен'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Подключённые устройства (${authProvider.deviceCount}):',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final isCurrentDevice = device['device_token'] == currentDeviceToken;
                            return ListTile(
                              title: Text(
                                'Устройство ${index + 1} (${device['device_token'].substring(0, 8)}...)',
                                style: theme.textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                '${device['device_model']} (${device['device_os']})\nПоследнее подключение: ${device['last_seen']}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              trailing: isCurrentDevice
                                  ? const Icon(Icons.block, color: Colors.grey)
                                  : IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeDevice(device['device_token']),
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
      ),
    );
  }
}