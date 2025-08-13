// lib/features/auth/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import '../models/domain/user.dart';
import 'auth_controller.dart';

export 'auth_controller.dart';

// Токен авторизации (читает AuthInterceptor)
final tokenProvider = StateProvider<String?>((ref) => null, name: 'authToken');

// Производные провайдеры от состояния
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authControllerProvider.select((s) => (s is FeatureReady<User>) ? s.data : null)),
  name: 'currentUser',
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider) != null,
  name: 'isAuthenticated',
);

final currentUsernameProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.username,
  name: 'currentUsername',
);
