import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/vpn_provider.dart';
import '../models/vpn_server.dart';

class VpnScreen extends StatelessWidget {
  const VpnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Статус подключения
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: vpnProvider.isConnected ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    vpnProvider.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: vpnProvider.isConnected ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (vpnProvider.selectedServer != null)
                    Text(
                      'Server: ${vpnProvider.selectedServer!.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Кнопка Connect/Disconnect
            ElevatedButton(
              onPressed: vpnProvider.isConnecting
                  ? null
                  : () async {
                      try {
                        if (vpnProvider.isConnected) {
                          await vpnProvider.disconnect();
                        } else {
                          await vpnProvider.connect();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: vpnProvider.isConnecting
                  ? const SpinKitCircle(color: Colors.white, size: 20)
                  : Text(vpnProvider.isConnected ? 'Disconnect' : 'Connect'),
            ),
            const SizedBox(height: 20),
            // Список серверов
            const Text(
              'Select Server',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: vpnProvider.servers.length,
                itemBuilder: (context, index) {
                  final server = vpnProvider.servers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Icon(
                        Icons.public,
                        color: vpnProvider.selectedServer == server ? Colors.blue : Colors.grey,
                      ),
                      title: Text(server.name),
                      subtitle: Text(server.country),
                      selected: vpnProvider.selectedServer == server,
                      onTap: () {
                        vpnProvider.selectServer(server);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}