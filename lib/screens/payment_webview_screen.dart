import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  String? _paymentUrl;
  bool _loading = false;
  String? _error;
  WebViewController? _mobileWebViewController;

  @override
  void initState() {
    super.initState();
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
        body: jsonEncode({'amount': 200.00, 'method': method}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final confirmationUrl = data['confirmationUrl'];
        if (confirmationUrl != null && confirmationUrl is String) {
          setState(() {
            _paymentUrl = confirmationUrl;
            _loading = false;
          });
          if ( _paymentUrl != null) {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _fetchPaymentUrl('bank_card'),
            child: const Text('Оплатить через карту'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchPaymentUrl('sberbank'),
            child: const Text('Оплатить через СберПей'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchPaymentUrl('sbp'),
            child: const Text('Оплатить через СБП'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    if (_paymentUrl == null) {
      return const Center(child: Text('Нет ссылки на оплату'));
    }
      if (_mobileWebViewController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return WebViewWidget(controller: _mobileWebViewController!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.7,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Оплата подписки'),
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
    super.dispose();
  }
} 