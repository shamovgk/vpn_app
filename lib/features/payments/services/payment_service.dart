import 'package:vpn_app/core/api_service.dart';

class PaymentService {
  final ApiService api;

  PaymentService(this.api);

  // Метод для создания ссылки оплаты
  Future<String> createPaymentUrl({
    required double amount,
    required String method,
  }) async {
    final res = await api.post('/pay', {
      'amount': amount,
      'method': method,
    }, auth: true);

    final confirmationUrl = res['confirmationUrl'];
    if (confirmationUrl is String && confirmationUrl.isNotEmpty) {
      return confirmationUrl;
    }
    throw Exception('Ошибка получения ссылки на оплату');
  }
}
