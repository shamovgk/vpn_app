import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('VPN App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VPN Status: ${vpnProvider.isConnected ? 'Connected' : 'Disconnected'}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                vpnProvider.toggleConnection();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                vpnProvider.isConnected ? 'Disconnect' : 'Connect',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: vpnProvider.selectedServer,
              hint: const Text('Select Server'),
              items: ['USA', 'Germany', 'Japan'].map((String server) {
                return DropdownMenuItem<String>(
                  value: server,
                  child: Text(server),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  vpnProvider.selectServer(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}