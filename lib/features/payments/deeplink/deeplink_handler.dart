// lib/features/payments/deeplink/deeplink_handler.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../core/api/http_client.dart' show appConfigProvider;

final paymentSuccessPrefixProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).paymentSuccessPrefix;
});
final paymentCancelPrefixProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).paymentCancelPrefix;
});

class _PaymentDeeplinkHandler {
  _PaymentDeeplinkHandler(this.ref);
  final Ref ref;

  AppLinks? _links;
  StreamSubscription<Uri>? _sub;

  void start() {
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    _links = AppLinks();

    unawaited(_handleInitial());

    _sub = _links!.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {},
    );
  }

  Future<void> _handleInitial() async {
    try {
      if (_links == null) return;
      final uri = await _links!.getInitialLink();
      if (uri != null) _handleUri(uri);
    } catch (_) {/* ignore */}
  }

  void _handleUri(Uri uri) {
    final successPref = ref.read(paymentSuccessPrefixProvider);
    final cancelPref = ref.read(paymentCancelPrefixProvider);

    final s = uri.toString();
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final router = GoRouter.of(ctx);

    if (s.startsWith(successPref)) {
      router.goNamed(AppRoute.subscription.name);
    } else if (s.startsWith(cancelPref)) {
      // Ничего — остаёмся на текущем экране
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _links = null;
  }
}

final paymentDeeplinkInitializerProvider = Provider<void>((ref) {
  final h = _PaymentDeeplinkHandler(ref)..start();
  ref.onDispose(h.dispose);
  return;
}, name: 'paymentDeeplinkInit');