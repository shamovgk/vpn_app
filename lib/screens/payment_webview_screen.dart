import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_windows;

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  String? _paymentUrl;
  bool _loading = false;
  String? _error;
  late final webview_windows.WebviewController _windowsController;
  bool _windowsWebViewReady = false;
  WebViewController? _mobileWebViewController;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _windowsController = webview_windows.WebviewController();
      _windowsController.initialize().then((_) {
        setState(() {
          _windowsWebViewReady = true;
        });
        if (_paymentUrl != null) {
          _windowsController.loadUrl(_paymentUrl!);
        }
      });
    }
  }

  Future<void> _fetchPaymentUrl(String method) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://95.214.10.8:3000/pay-yookassa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': 1.00, 'method': method}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final confirmationUrl = data['confirmationUrl'];
        if (confirmationUrl != null && confirmationUrl is String) {
          setState(() {
            _paymentUrl = confirmationUrl;
            _loading = false;
          });
          if (Platform.isWindows && _windowsWebViewReady) {
            _windowsController.loadUrl(_paymentUrl!);
          } else if (!Platform.isWindows && _paymentUrl != null) {
            _mobileWebViewController = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse(_paymentUrl!));
          }
        } else {
          setState(() {
            _error = 'Ошибка получения ссылки на оплату';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Ошибка сервера: ${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка оплаты: $e';
        _loading = false;
      });
    }
  }

  Widget _buildMethodSelection() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _fetchPaymentUrl('bank_card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  elevation: 2,
                ),
                child: Text('Оплатить через карту', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onPrimary)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _fetchPaymentUrl('sberbank'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  elevation: 2,
                ),
                child: Text('Оплатить через СберПей', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onPrimary)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _fetchPaymentUrl('sbp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  elevation: 2,
                ),
                child: Text('Оплатить через СБП', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    if (_paymentUrl == null) {
      return const Center(child: Text('Нет ссылки на оплату'));
    }
    if (Platform.isWindows) {
      if (!_windowsWebViewReady) {
        return const Center(child: CircularProgressIndicator());
      }
      return webview_windows.Webview(_windowsController);
    } else {
      if (_mobileWebViewController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return WebViewWidget(controller: _mobileWebViewController!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Оплата подписки',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _paymentUrl == null
                    ? _buildMethodSelection()
                    : _buildWebView(),
      ),
    );
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }
} 