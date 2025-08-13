// lib/ui/widgets/themed_scaffold.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class ThemedScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final bool safeArea;
  final Color? overlayColor;

  const ThemedScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.safeArea = true,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    final background = DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        image: DecorationImage(
          image: const AssetImage('assets/background.png'),
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.1),
          opacity: t.opacities.overlay,
        ),
      ),
      child: overlayColor == null ? const SizedBox.expand() : ColoredBox(color: overlayColor!),
    );

    final content = safeArea ? SafeArea(child: body) : body;

    return Stack(
      children: [
        Positioned.fill(child: background),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          drawer: drawer,
          floatingActionButton: floatingActionButton,
          body: content,
        ),
      ],
    );
  }
}
