import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TrayManagerHandler with tray.TrayListener {
  TrayManagerHandler() {
    _initializeTray();
  }

  Future<void> _initializeTray() async {
    await tray.TrayManager.instance.setIcon('assets/tray_icon.ico');

    final menu = tray.Menu(
      items: [
        tray.MenuItem(key: 'show_window', label: 'Show Window',),
        tray.MenuItem(key: 'connect', label: 'Connect'),
        tray.MenuItem(key: 'disconnect', label: 'Disconnect'),
        tray.MenuItem(key: 'exit', label: 'Exit App'),
      ],
    );
    await tray.TrayManager.instance.setContextMenu(menu);
    tray.TrayManager.instance.addListener(this);
  }

  @override
  void onTrayIconRightMouseDown() {
    tray.TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        break;
      case 'connect':
        vpnProvider.connect().then((_) => logger.i('VPN connected from tray')).catchError((e) => logger.e('Connect error: $e'));
        break;
      case 'disconnect':
        vpnProvider.disconnect().then((_) => logger.i('VPN disconnected from tray')).catchError((e) => logger.e('Disconnect error: $e'));
        break;
      case 'exit':
        vpnProvider.disconnect().then((_) => logger.i('VPN disconnected from tray')).catchError((e) => logger.e('Disconnect error: $e'));
        tray.TrayManager.instance.destroy();
        windowManager.destroy();
        break;
    }
  }

  void dispose() {
    tray.TrayManager.instance.removeListener(this);
  }
}