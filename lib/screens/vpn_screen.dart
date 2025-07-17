import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/vpn_provider.dart';
import 'package:vpn_app/screens/about_screen.dart';
import 'package:vpn_app/screens/settings_screen.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/login_screen.dart';
import 'package:vpn_app/screens/payment_webview_screen.dart';
import 'package:gif/gif.dart';
import 'package:vpn_app/services/api_service.dart';

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  bool _hasShownTrialNotification = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.trialEndDate != null && !_hasShownTrialNotification) {
      final trialEnd = DateTime.tryParse(user.trialEndDate!);
      if (trialEnd != null) {
        final daysLeft = trialEnd.difference(DateTime.now()).inDays;
        if (daysLeft > 0 && !user.isPaid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Вам доступен пробный период в $daysLeft дней'),
                backgroundColor: Colors.blue[600],
                duration: const Duration(seconds: 3),
              ),
            );
            _hasShownTrialNotification = true;
          });
        } else if (!user.isPaid && trialEnd.isBefore(DateTime.now())) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Срок действия пробного периода истёк, оплатите VPN'),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Оплатить',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentWebViewScreen()),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ),
            );
            _hasShownTrialNotification = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

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
              'UgbuganVPN',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
            ),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: theme.textTheme.headlineLarge?.color),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          drawer: Drawer(
            backgroundColor: theme.scaffoldBackgroundColor,
            width: 200,
            shape: const LinearBorder(),
            child: SizedBox(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: double.infinity,
                    color: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Text(
                      textAlign: TextAlign.center,
                      user?.username ?? 'Гость',
                      style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
                    ),
                  ),
                  Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.payment, color: theme.textTheme.bodyMedium?.color),
                        title: Text('Подписаться', style: theme.textTheme.bodyMedium),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PaymentWebViewScreen()),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.settings, color: theme.textTheme.bodyMedium?.color),
                        title: Text('Настройки', style: theme.textTheme.bodyMedium),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.info, color: theme.textTheme.bodyMedium?.color),
                        title: Text('О нас', style: theme.textTheme.bodyMedium),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.brightness_6, color: theme.textTheme.bodyMedium?.color),
                        title: Text('Смена темы', style: theme.textTheme.bodyMedium),
                        onTap: () {
                          Navigator.pop(context);
                          themeProvider.toggleTheme();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Тема изменена на ${themeProvider.themeMode == ThemeMode.dark ? 'Тёмную' : 'Светлую'}'),
                              backgroundColor: Colors.green[600],
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout, color: theme.textTheme.bodyMedium?.color),
                        title: Text('Выйти', style: theme.textTheme.bodyMedium),
                        onTap: () async {
                          Navigator.pop(context);
                          await authProvider.logout();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Вы вышли из аккаунта'),
                              backgroundColor: Colors.green[600],
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (Route<dynamic> route) => false,
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
              child: Transform.translate(
                offset: const Offset(0, -18.5),
                child: const AnimationButton(),
              ),
            ),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (vpnProvider.isConnecting || _isAnimating || user == null) return;

    final allowed = vpnProvider.isConnectionAllowed(
      isPaid: user.isPaid,
      trialEndDate: user.trialEndDate,
      deviceCount: user.deviceCount,
      subscriptionLevel: user.subscriptionLevel,
    );
    if (!allowed) return;

    setState(() {
      _isAnimating = true;
      _currentIsConnected = vpnProvider.isConnected;
    });

    _controller.reset();
    _controller.forward();
    try {
      if (_currentIsConnected) {
        await Future.delayed(const Duration(seconds: 4));
        await vpnProvider.disconnect();
      } else {
        await vpnProvider.connect(
          baseUrl: ApiService.baseUrl,
          token: authProvider.token!,
          isPaid: user.isPaid,
          trialEndDate: user.trialEndDate,
          deviceCount: user.deviceCount,
          subscriptionLevel: user.subscriptionLevel,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка подключения: $e'),
          backgroundColor: theme.colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final isAllowed = user != null
        ? vpnProvider.isConnectionAllowed(
            isPaid: user.isPaid,
            trialEndDate: user.trialEndDate,
            deviceCount: user.deviceCount,
            subscriptionLevel: user.subscriptionLevel,
          )
        : false;

    return GestureDetector(
      onTap: isAllowed ? handleTap : null,
      child: AbsorbPointer(
        absorbing: !isAllowed,
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
      ),
    );
  }
}
