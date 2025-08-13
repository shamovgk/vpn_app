// lib/features/subscription/repositories/subscription_repository_impl.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:vpn_app/core/api/api_service.dart';
import 'package:vpn_app/core/cache/swr/swr_keys.dart';
import 'package:vpn_app/core/cache/swr/swr_store.dart';
import 'package:vpn_app/core/errors/error_mapper.dart';
import 'package:vpn_app/features/subscription/mappers/subscription_mapper.dart';
import '../../../core/cache/disk_cache.dart';
import '../models/subscription_status.dart';
import 'subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(
    this.api, {
    this.ttl = const Duration(seconds: 60),
    required SwrStore swr,
  }) : _entry = swr.register<SubscriptionStatus>(
          key: SwrKeys.subscription,
          ttl: ttl,
          fetcher: () async {
            final res = await api.get(_statusPath);
            final code = res.statusCode ?? 0;
            if (code < 200 || code >= 300) throwFromResponse(res);
            final data = (res.data is Map)
                ? (res.data as Map).cast<String, dynamic>()
                : <String, dynamic>{};
            // Сохраним снапшот
            unawaited(DiskCache.putJson(SwrKeys.subscription, data));
            return subscriptionStatusFromMap(data);
          },
        ) {
    // Гидратация из снапшота
    _hydrateFromSnapshot();
  }

  final ApiService api;
  final Duration ttl;
  static const _statusPath = '/subscription/status';

  final SwrEntry<SubscriptionStatus> _entry;

  Future<void> _hydrateFromSnapshot() async {
    final snap = await DiskCache.getJson<Map>(SwrKeys.subscription, ttl: ttl);
    if (snap != null && snap.isNotEmpty) {
      final mapped = subscriptionStatusFromMap(snap.cast<String, dynamic>());
      _entry.setOptimistic(mapped);
    }
  }

  @override
  SubscriptionStatus? getCached() => _entry.value;

  @override
  bool isCacheFresh() => _entry.value != null;

  @override
  Future<SubscriptionStatus> fetchFresh({CancelToken? cancelToken}) async {
    try {
      final res = await api.get(_statusPath, cancelToken: cancelToken);
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) throwFromResponse(res);

      final data = (res.data is Map)
          ? (res.data as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final fresh = subscriptionStatusFromMap(data);

      // кладём свежие данные и снапшот
      _entry.setOptimistic(fresh);
      unawaited(DiskCache.putJson(SwrKeys.subscription, data));
      return fresh;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

