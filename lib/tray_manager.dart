import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:vpn_app/main.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/vpn/providers/vpn_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TrayManagerHandler with tray.TrayListener {
  TrayManagerHandler() {
    _initializeTray();
  }

  bool _isInitialized = false;

  Future<void> _initializeTray() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await tray.TrayManager.instance.setIcon('assets/tray_icon_disconnect.ico');
    tray.TrayManager.instance.addListener(this);
  }

  Future<void> updateTrayIconAndMenu() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Используем Riverpod context.read для доступа к провайдерам
    final container = ProviderScope.containerOf(context);
    final vpnState = container.read(vpnProvider);
    final authState = container.read(authProvider);

    final menu = tray.Menu(
      items: [
        tray.MenuItem(key: 'show_window', label: 'Show Window'),
        tray.MenuItem.separator(),
        tray.MenuItem(
          key: 'connect',
          label: 'Connect',
          disabled: !authState.isLoggedIn ||
                    vpnState.isConnected ||
                    vpnState.isConnecting,
        ),
        tray.MenuItem(
          key: 'disconnect',
          label: 'Disconnect',
          disabled: !authState.isLoggedIn || !vpnState.isConnected,
        ),
        tray.MenuItem.separator(),
        tray.MenuItem(key: 'exit', label: 'Exit App'),
      ],
    );
    await tray.TrayManager.instance.setContextMenu(menu);
    final iconPath = vpnState.isConnected
        ? 'assets/tray_icon_connect.ico'
        : 'assets/tray_icon_disconnect.ico';
    await tray.TrayManager.instance.setIcon(iconPath);
  }

  @override
  void onTrayIconRightMouseDown() {
    updateTrayIconAndMenu();
    tray.TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final container = ProviderScope.containerOf(context);
    final vpnNotifier = container.read(vpnProvider.notifier);
    final vpnState = container.read(vpnProvider);
    final authState = container.read(authProvider);

    final user = authState.user;

    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        break;
      case 'connect':
        if (!authState.isLoggedIn || user == null) {
          logger.w('Cannot connect: Not authenticated');
          return;
        }
        if (vpnState.isConnected || vpnState.isConnecting) {
          logger.w('Cannot connect: Already connected or connecting');
          return;
        }
        try {
          await vpnNotifier.connect(
          );
        } catch (e) {
          logger.e('Tray connect error: $e');
        }
        break;
      case 'disconnect':
        try {
          await vpnNotifier.disconnect();
        } catch (e) {
          logger.e('Tray disconnect error: $e');
        }
        break;
      case 'exit':
        try {
          await vpnNotifier.disconnect();
        } catch (e) {
          logger.e('Disconnect error: $e');
        }
        tray.TrayManager.instance.destroy();
        windowManager.destroy();
        break;
    }
    logger.i('Menu item clicked: ${menuItem.key}');
  }

  void dispose() {
    tray.TrayManager.instance.removeListener(this);
    _isInitialized = false;
  }
}

late TrayManagerHandler trayHandler;
