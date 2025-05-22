import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Settings'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _privateKeyController,
              decoration: const InputDecoration(labelText: 'Private Key'),
              obscureText: true,
            ),
            TextField(
              controller: _serverPublicKeyController,
              decoration: const InputDecoration(labelText: 'Server Public Key'),
            ),
            TextField(
              controller: _serverAddressController,
              decoration: const InputDecoration(labelText: 'Server Address (IP:Port)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await vpnProvider.saveConfig(
                    privateKey: _privateKeyController.text,
                    serverPublicKey: _serverPublicKeyController.text,
                    serverAddress: _serverAddressController.text,
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}