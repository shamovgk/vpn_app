import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit, Process;
import '../providers/vpn_provider.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VpnScreen(),
    );
  }
}

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  int _selectedIndex = 0; // Индекс активной страницы
  bool _isVisible = true;
  static const platform = MethodChannel('tray');

  static final List<Widget> _pages = <Widget>[
    _HomeContent(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      window_size.setWindowMinSize(const Size(360, 640));
      window_size.setWindowMaxSize(const Size(360, 640));
      window_size.setWindowFrame(Rect.fromLTWH(0, 0, 360, 640));
    }
    platform.setMethodCallHandler((call) async {
      if (call.method == "show") {
        setState(() {
          _isVisible = true;
        });
        window_size.setWindowFrame(Rect.fromLTWH(0, 0, 360, 640));
      } else if (call.method == "hide") {
        setState(() {
          _isVisible = false;
        });
      } else if (call.method == "connect") {
        final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
        await _handleVpnAction(vpnProvider, true);
      } else if (call.method == "disconnect") {
        final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
        await _handleVpnAction(vpnProvider, false);
      } else if (call.method == "exit") {
        final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
        await _shutdownApp(vpnProvider);
      }
    });
  }

  Future<void> _handleVpnAction(VpnProvider vpnProvider, bool connect) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      if (connect) {
        await vpnProvider.connect();
      } else {
        await vpnProvider.disconnect();
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _shutdownApp(VpnProvider vpnProvider) async {
    try {
      if (vpnProvider.isConnected) {
        await vpnProvider.disconnect();
        print('VPN disconnected on exit');
        if (Platform.isWindows) {
          final result = await Process.run('taskkill', ['/IM', 'wireguard_svc.exe', '/F']);
          print('WireGuard process kill result: ${result.stdout} ${result.stderr}');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      exit(0); // Завершаем процесс
    } catch (e) {
      print('Error during shutdown: $e');
      exit(0);
    }
  }

  @override
  void dispose() {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    if (vpnProvider.isConnected) {
      vpnProvider.disconnect().then((_) {
        print('VPN disconnected on dispose');
      }).catchError((e) {
        print('Error disconnecting VPN on dispose: $e');
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && Platform.isWindows) {
          setState(() {
            _isVisible = false;
          });
          await platform.invokeMethod('hide');
        }
      },
      child: Visibility(
        visible: _isVisible,
        child: Scaffold(
          backgroundColor: Color(0xFF142F1F),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _pages[_selectedIndex],
                ),
                Container(
                  padding: EdgeInsets.zero,
                  color: Color(0xFF142F1F).withAlpha(230),
                  child: BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                      BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: Color(0xFF719EA6),
                    unselectedItemColor: Color(0xFFABCF9C).withAlpha(150),
                    onTap: _onItemTapped,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
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

// Содержимое главной страницы с плейсхолдером и кнопкой
class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          ),
          child: vpnProvider.isConnecting
              ? Container(
                  key: const ValueKey('connecting'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitCircle(color: Color(0xFF719EA6), size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Подключение... (Плейсхолдер)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF719EA6),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  vpnProvider.isConnected ? 'Подключено' : 'Отключено',
                  key: ValueKey(vpnProvider.isConnected),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: vpnProvider.isConnected
                        ? Color(0xFFABCF9C)
                        : Color(0xFF719EA6),
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

                    Future<void> handleVpnAction() async {
                      if (vpnProvider.isConnected) {
                        await vpnProvider.disconnect();
                      } else {
                        await vpnProvider.connect();
                      }
                    }

                    try {
                      await handleVpnAction();
                    } catch (e) {
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Ошибка: $e')),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: vpnProvider.isConnected
                  ? Colors.red
                  : Color(0xFF719EA6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 5,
            ),
            child: vpnProvider.isConnecting
                ? SpinKitCircle(color: Colors.white, size: 24)
                : Text(
                    vpnProvider.isConnected ? 'Отключить' : 'Подключить',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}