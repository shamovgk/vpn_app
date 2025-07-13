import 'package:flutter/material.dart';
import 'package:yookassa_payments_flutter/yookassa_payments_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  Future<void> _pay(BuildContext context, String method) async {
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
          if (await canLaunchUrl(Uri.parse(confirmationUrl))) {
            await launchUrl(Uri.parse(confirmationUrl), mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось открыть страницу оплаты')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка получения ссылки на оплату')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сервера: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка оплаты: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата подписки'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pay(context, 'bank_card'),
              child: const Text('Оплатить через карту'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pay(context, 'sberbank'),
              child: const Text('Оплатить через СберПей'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pay(context, 'sbp'),
              child: const Text('Оплатить через СБП'),
            ),
          ],
        ),
      ),
    );
  }
}