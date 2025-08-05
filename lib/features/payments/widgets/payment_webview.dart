import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_windows;

/// Универсальный виджет для показа WebView оплаты на всех платформах
class PaymentWebView extends StatelessWidget {
  final String url;
  final VoidCallback onPaymentSuccess;

  const PaymentWebView({
    super.key,
    required this.url,
    required this.onPaymentSuccess,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _WindowsPaymentWebView(url: url, onPaymentSuccess: onPaymentSuccess);
    } else {
      return _MobilePaymentWebView(url: url, onPaymentSuccess: onPaymentSuccess);
    }
  }
}

// --- Мобильная версия WebView ---
class _MobilePaymentWebView extends StatefulWidget {
  final String url;
  final VoidCallback onPaymentSuccess;

  const _MobilePaymentWebView({
    required this.url,
    required this.onPaymentSuccess,
  });

  @override
  State<_MobilePaymentWebView> createState() => _MobilePaymentWebViewState();
}

class _MobilePaymentWebViewState extends State<_MobilePaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith('https://sham.shetanvpn.ru/mainscreen')) {
              widget.onPaymentSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

// --- Windows версия WebView ---
class _WindowsPaymentWebView extends StatefulWidget {
  final String url;
  final VoidCallback onPaymentSuccess;

  const _WindowsPaymentWebView({
    required this.url,
    required this.onPaymentSuccess,
  });

  @override
  State<_WindowsPaymentWebView> createState() => _WindowsPaymentWebViewState();
}

class _WindowsPaymentWebViewState extends State<_WindowsPaymentWebView> {
  late final webview_windows.WebviewController _controller;
  StreamSubscription<String>? _urlSub;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = webview_windows.WebviewController();
    _controller.initialize().then((_) {
      setState(() => _ready = true);
      _controller.loadUrl(widget.url);
      _urlSub = _controller.url.listen((url) {
        if (url.startsWith('https://sham.shetanvpn.ru/mainscreen')) {
          widget.onPaymentSuccess();
        }
      });
    });
  }

  @override
  void dispose() {
    _urlSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return webview_windows.Webview(_controller);
  }
}
