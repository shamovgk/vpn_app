import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/vpn_provider.dart';
import 'package:logger/logger.dart';
import 'package:gif/gif.dart';
import 'package:vpn_app/screens/settings_screen.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/login_screen.dart';

final logger = Logger();

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  void _onItemTapped(BuildContext context, int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выхода: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'TowerVPN',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          width: 200,
          shape: LinearBorder(),
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                  child: Text(
                    textAlign: TextAlign.center,
                    authProvider.isAuthenticated ? authProvider.username ?? 'Пользователь' : 'Гость',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.payment),
                      title: const Text('Подписаться'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Переход к Подписке')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Настройки'),
                      onTap: () {
                        Navigator.pop(context);
                        _onItemTapped(context, 1);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Помощь'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Переход в Помощь')),
                        );
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text('Смена темы'),
                      onTap: () {
                        Navigator.pop(context);
                        themeProvider.toggleTheme();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Тема изменена на ${themeProvider.themeMode == ThemeMode.dark ? 'Тёмную' : 'Светлую'}'),
                            backgroundColor: Theme.of(context).extension<CustomColors>()!.success,
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Выйти'),
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: _AnimationButton(),
          ),
        ),
      ),
    );
  }
}

class _AnimationButton extends StatefulWidget {
  const _AnimationButton();

  @override
  __AnimationButtonState createState() => __AnimationButtonState();
}

class __AnimationButtonState extends State<_AnimationButton> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late GifController _controller;
  bool _isAnimating = false;
  bool _currentIsConnected = false;
  bool _isInitialized = false;
  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);
    _controller.reset();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isAnimating && mounted) {
        setState(() {
          _isAnimating = false;
          final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
          _currentIsConnected = vpnProvider.isConnected;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        setState(() {
          _isInitialized = true;
          final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
          _currentIsConnected = vpnProvider.isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _handleTap() async {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    if (vpnProvider.isConnecting || _isAnimating) return;

    setState(() {
      _isAnimating = true; 
      _currentIsConnected = vpnProvider.isConnected; 
    });

    try {
      _controller.reset();
      await _controller.forward(); 
      if (_currentIsConnected) {
        await vpnProvider.disconnect(); 
      } else {
        await vpnProvider.connect(); 
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 300,
        height: 300,
        child: Gif(
          image: _currentIsConnected
              ? const AssetImage('assets/dark_theme_vpn_disconnect.gif') 
              : const AssetImage('assets/dark_theme_vpn_connect.gif'),   
          controller: _controller,
          autostart: Autostart.no,
          placeholder: (context) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}