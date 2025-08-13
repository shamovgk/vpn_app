// lib/features/subscription/usecases/fetch_subscription_status_usecase.dart
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_status.dart';
import '../providers/subscription_providers.dart';

/// Теперь можно передавать CancelToken из контроллера.
typedef FetchSubscriptionStatus = Future<SubscriptionStatus> Function({
  CancelToken? cancelToken,
});

final fetchSubscriptionStatusUseCaseProvider =
    Provider<FetchSubscriptionStatus>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return ({CancelToken? cancelToken}) =>
      repo.fetchFresh(cancelToken: cancelToken);
}, name: 'fetchSubscriptionStatusUC');
