import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/vpn_provider.dart';
import 'package:logger/logger.dart';
import 'package:gif/gif.dart';
import 'package:vpn_app/screens/settings_screen.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/login_screen.dart';
import 'package:vpn_app/screens/payment_screen.dart';

final logger = Logger();

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => VpnScreenState();
}

class VpnScreenState extends State<VpnScreen> {
  final GlobalKey<AnimationButtonState> _animationButtonKey = GlobalKey<AnimationButtonState>();
  static VpnScreenState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  static GlobalKey<AnimationButtonState>? getAnimationButtonKey() => _instance?._animationButtonKey;

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
            'UgbuganVPN',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaymentScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Настройки'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
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
                        authProvider.logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: AnimationButton(key: _animationButtonKey),
          ),
        ),
      ),
    );
  }
}

class AnimationButton extends StatefulWidget {
  const AnimationButton({super.key});

  @override
  AnimationButtonState createState() => AnimationButtonState();
}

class AnimationButtonState extends State<AnimationButton> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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
          _currentIsConnected = Provider.of<VpnProvider>(context, listen: false).isConnected;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        setState(() {
          _isInitialized = true;
          _currentIsConnected = Provider.of<VpnProvider>(context, listen: false).isConnected;
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

  Future<void> handleTap() async {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    if (vpnProvider.isConnecting || _isAnimating) return;

    setState(() {
      _isAnimating = true; 
      _currentIsConnected = vpnProvider.isConnected; 
    });

    _controller.reset();
    await _controller.forward(); 
    if (_currentIsConnected) {
      await vpnProvider.disconnect();
    } else {
      await vpnProvider.connect();
    }

    setState(() {
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: handleTap,
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