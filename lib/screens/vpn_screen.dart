import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import 'settings_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[_HomeContent(), SettingsScreen(),];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _pages[_selectedIndex]),
            Container(
              padding: EdgeInsets.zero,
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(230),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: const Color(0xFFABCF9C).withAlpha(150),
                onTap: _onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: vpnProvider.isConnecting
                ? Container(
                    key: const ValueKey('connecting'),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitCircle(color: Theme.of(context).primaryColor, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          'Подключение... (Плейсхолдер)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    vpnProvider.isConnected ? 'Подключено' : 'Отключено',
                    key: ValueKey(vpnProvider.isConnected),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: vpnProvider.isConnected
                              ? const Color(0xFFABCF9C)
                              : Theme.of(context).primaryColor,
                        ),
                  ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: vpnProvider.isConnecting
                  ? null
                  : () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      if (!authProvider.isAuthenticated) {
                        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Не авторизован')));
                        return;
                      }
                      try {
                        if (vpnProvider.isConnected) {
                          await vpnProvider.disconnect();
                        } else {
                          await vpnProvider.connect();
                        }
                      } catch (e) {
                        if (context.mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: vpnProvider.isConnected ? Colors.red : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 5,
              ),
              child: vpnProvider.isConnecting
                  ? SpinKitCircle(color: Colors.white, size: 24)
                  : Text(
                      vpnProvider.isConnected ? 'Отключить' : 'Подключить',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}