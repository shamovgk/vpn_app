import 'package:flutter/material.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:yookassa_payments_flutter/yookassa_payments_flutter.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _startYooKassaPayment() async {
    final inputData = TokenizationModuleInputData(
      clientApplicationKey: "test_MTEyMjQ0MSqrqcX4g-vCoVYtikMGgUH7KW4erq05DU0", // из личного кабинета YooKassa
      shopId: "1122441", // из личного кабинета YooKassa
      title: "VPN Premium",
      subtitle: "Доступ на месяц",
      amount: Amount(value: "200.00", currency: Currency.rub), // сумма и валюта
      savePaymentMethod: SavePaymentMethod.userSelects,
      tokenizationSettings: TokenizationSettings(
        PaymentMethodTypes([
          PaymentMethod.bankCard,
          PaymentMethod.sberbank,
          PaymentMethod.sbp,
        ]),
      ),
    );

    try {
      final result = await YookassaPaymentsFlutter.tokenization(inputData);

      if (result is SuccessTokenizationResult) {
        // Успех — отправь result.token на свой сервер для создания платежа через API YooKassa
        print('TOKEN: ${result.token}');
        // Покажи пользователю успех
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Оплата прошла, токен получен!')),
        );
      } else {
        // отмена или ошибка
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Оплата отменена')),
        );
      }
    } catch (e) {
      // Ошибка SDK
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка оплаты: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Оплата подписки',
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyMedium?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Введите данные карты для оплаты',
                style: theme.textTheme.headlineLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cardNumberController,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                decoration: InputDecoration(
                  labelText: 'Номер карты',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card, color: theme.textTheme.bodyMedium?.color),
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 16) {
                    return 'Введите корректный номер карты (16 цифр)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today, color: theme.textTheme.bodyMedium?.color),
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.isEmpty || !RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) {
                          return 'Введите дату в формате MM/YY';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock, color: theme.textTheme.bodyMedium?.color),
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 3) {
                          return 'Введите корректный CVV (3 цифры)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Оплата успешно обработана (мок-данные)'),
                        backgroundColor: customColors?.success ?? Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Проверьте введённые данные'),
                        backgroundColor:Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
                style: theme.elevatedButtonTheme.style?.copyWith(
                  minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
                ),
                child: Text(
                  'Оплатить',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Сумма: 499 ₽/месяц',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(153),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startYooKassaPayment,
                child: Text('Оплатить через ЮKassa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}