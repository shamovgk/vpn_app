import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _privateKeyController = TextEditingController();
  final _serverPublicKeyController = TextEditingController();
  final _serverAddressController = TextEditingController();

  @override
  void dispose() {
    _privateKeyController.dispose();
    _serverPublicKeyController.dispose();
    _serverAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Settings'),
        backgroundColor: const Color(0xFF142F1F),
        foregroundColor: const Color(0xFF719EA6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _privateKeyController,
              decoration: const InputDecoration(
                labelText: 'Private Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverPublicKeyController,
              decoration: const InputDecoration(
                labelText: 'Server Public Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverAddressController,
              decoration: const InputDecoration(
                labelText: 'Server Address (IP:Port)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final privateKey = _privateKeyController.text.trim();
                final serverPublicKey = _serverPublicKeyController.text.trim();
                final serverAddress = _serverAddressController.text.trim();

                if (privateKey.isEmpty || serverPublicKey.isEmpty || serverAddress.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Все поля должны быть заполнены')),
                  );
                  return;
                }
                if (!privateKey.endsWith('=') || privateKey.length < 40) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Неверный формат Private Key')),
                  );
                  return;
                }
                if (!serverPublicKey.endsWith('=') || serverPublicKey.length < 40) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Неверный формат Server Public Key')),
                  );
                  return;
                }
                if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}$').hasMatch(serverAddress)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Неверный формат Server Address (IP:Port)')),
                  );
                  return;
                }

                try {
                  await vpnProvider.saveConfig(
                    privateKey: privateKey,
                    serverPublicKey: serverPublicKey,
                    serverAddress: serverAddress,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Конфигурация сохранена')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF719EA6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}