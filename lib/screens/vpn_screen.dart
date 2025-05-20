import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/vpn_provider.dart';

class VpnScreen extends StatelessWidget {
  const VpnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN App'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Статус подключения
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: vpnProvider.isConnected ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  vpnProvider.isConnected ? 'Connected' : 'Disconnected',
                  key: ValueKey(vpnProvider.isConnected),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: vpnProvider.isConnected ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Кнопка Connect/Disconnect
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
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
                  backgroundColor: vpnProvider.isConnected ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: vpnProvider.isConnecting
                    ? const SpinKitCircle(color: Colors.white, size: 24)
                    : Text(
                        vpnProvider.isConnected ? 'Disconnect' : 'Connect',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}