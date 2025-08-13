// lib/features/subscription/providers/subscription_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/api/api_service.dart';
import 'package:vpn_app/core/cache/swr/swr_store.dart';
import 'package:vpn_app/features/subscription/providers/subscription_controller.dart';
import '../models/subscription_state.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/subscription_repository_impl.dart';

export 'subscription_controller.dart';
export 'package:vpn_app/features/subscription/usecases/fetch_subscription_status_usecase.dart';

// TTL статуса подписки
final subscriptionStatusTtlProvider =
    Provider<Duration>((_) => const Duration(seconds: 60), name: 'subscriptionStatusTtl');

// Репозиторий подписки
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final swr = ref.read(swrStoreProvider);
  return SubscriptionRepositoryImpl(
    ref.read(apiServiceProvider),
    ttl: ref.read(subscriptionStatusTtlProvider),
    swr: swr,
  );
}, name: 'subscriptionRepository');

// Доступ к VPN исходя из статуса подписки
final vpnAccessProvider = Provider<bool>((ref) {
  final subState = ref.watch(subscriptionControllerProvider);
  return subState is SubscriptionReady ? subState.status.canUse : false;
}, name: 'vpnAccess');
