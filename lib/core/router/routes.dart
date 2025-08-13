// lib/core/router/routes.dart
import 'package:go_router/go_router.dart';

enum AppRoute {
  gate('/gate'),
  login('/login'),
  register('/register'),
  verify('/verify'),
  reset('/reset'),
  vpn('/vpn'),
  devices('/devices'),
  subscription('/subscription'),
  about('/about'),
  payment('/payment');

  final String path;
  const AppRoute(this.path);
}

extension GoRouterX on GoRouter {
  void goRoute(
    AppRoute r, {
    Map<String, dynamic>? query,
    Object? extra,
  }) =>
      goNamed(
        r.name,
        queryParameters: query ?? const <String, dynamic>{},
        extra: extra,
      );

  Future<T?> pushRoute<T>(
    AppRoute r, {
    Map<String, dynamic>? query,
    Object? extra,
  }) =>
      pushNamed<T>(
        r.name,
        queryParameters: query ?? const <String, dynamic>{},
        extra: extra,
      );
}
