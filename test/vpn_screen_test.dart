import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/vpn_provider.dart';
import 'package:vpn_app/screens/vpn_screen.dart';

void main() {
  testWidgets('VPN screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VpnProvider()),
        ],
        child: const MaterialApp(home: VpnScreen()),
      ),
    );

    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
  });

  testWidgets('Connect button toggles state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VpnProvider()),
        ],
        child: const MaterialApp(home: VpnScreen()),
      ),
    );

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Disconnect'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
  });
}