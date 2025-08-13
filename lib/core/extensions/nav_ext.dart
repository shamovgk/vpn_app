// lib/core/extensions/nav_ext.dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vpn_app/features/payments/screens/payment_webview_screen.dart';
import '../router/app_router.dart';
import '../router/routes.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/subscription/providers/subscription_providers.dart';

extension NavX on BuildContext {
  // Базовые
  void goLogin() => goNamed(AppRoute.login.name);
  void goVpn() => goNamed(AppRoute.vpn.name);

  // Auth flow
  void pushRegister() => pushNamed(AppRoute.register.name);
  void goVerify({required String u, required String e}) =>
      goNamed(AppRoute.verify.name, queryParameters: <String, dynamic>{'u': u, 'e': e});
  void pushReset({required String u}) =>
      pushNamed(AppRoute.reset.name, queryParameters: <String, dynamic>{'u': u});

  // Разделы
  void pushDevices() => pushNamed(AppRoute.devices.name);
  void pushSubscription() => pushNamed(AppRoute.subscription.name);
  void pushAbout() => pushNamed(AppRoute.about.name);

  // Платёжка
  void pushPayment(PaymentWebViewArgs args) =>
      pushNamed(AppRoute.payment.name, extra: args);

  // === Типобезопасные guard-хелперы ===

  /// Если не авторизован — редиректим на логин и выходим.
  Future<void> pushAuthRequired(
    WidgetRef ref,
    String routeName, {
    Map<String, dynamic>? query,
    Object? extra,
  }) async {
    final isAuth = ref.read(isAuthenticatedProvider);
    if (!isAuth) {
      goNamed(AppRoute.login.name);
      return;
    }
    await pushNamed(
      routeName,
      queryParameters: query ?? const <String, dynamic>{},
      extra: extra,
    );
  }

  /// Если есть активная подписка — заменяем на домашний (VPN), иначе идем по указанному роуту.
  Future<void> pushReplaceOnSubscribed(
    WidgetRef ref,
    String routeName, {
    Map<String, dynamic>? query,
    Object? extra,
  }) async {
    final canUse = ref.read(vpnAccessProvider);
    if (canUse) {
      goNamed(AppRoute.vpn.name);
      return;
    }
    await pushNamed(
      routeName,
      queryParameters: query ?? const <String, dynamic>{},
      extra: extra,
    );
  }

  /// Открыть оплату: если нет подписки — стандартный push, если подписка уже есть — отправляем на VPN.
  void openPaymentGuarded(WidgetRef ref, PaymentWebViewArgs args) {
    final canUse = ref.read(vpnAccessProvider);
    if (canUse) {
      goNamed(AppRoute.vpn.name);
    } else {
      pushPayment(args);
    }
  }
}

// Root навконтекст, когда нужно дернуть вне дерева
BuildContext get rootCtx {
  final ctx = rootNavigatorKey.currentContext;
  assert(ctx != null, 'rootNavigatorKey.currentContext is null: router not ready yet');
  if (ctx == null) {
    throw StateError('Root navigator context is not available yet');
  }
  return ctx;
}

BuildContext? get rootCtxOrNull => rootNavigatorKey.currentContext;