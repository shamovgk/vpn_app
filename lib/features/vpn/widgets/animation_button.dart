import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

class AnimationButton extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final Future<void> Function()? onConnect; 

  const AnimationButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    this.onConnect,
  });

  @override
  State<AnimationButton> createState() => _AnimationButtonState();
}

class _AnimationButtonState extends State<AnimationButton> with TickerProviderStateMixin {
  late GifController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant AnimationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Запускаем анимацию только при смене состояния подключения
    if (oldWidget.isConnected != widget.isConnected) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isConnecting || widget.onConnect == null) return;
    _controller.reset();
    _controller.forward();
    await widget.onConnect?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isConnecting ? null : _handleTap,
      child: AbsorbPointer(
        absorbing: widget.isConnecting,
        child: SizedBox(
          width: 300,
          height: 300,
          child: Gif(
            image: widget.isConnected
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
