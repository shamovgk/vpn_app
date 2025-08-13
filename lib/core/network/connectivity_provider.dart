// lib/core/network/connectivity_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../cache/swr/swr_store.dart';

enum OnlineStatus { online, offline, unknown }

OnlineStatus _mapFromList(List<ConnectivityResult> list) {
  if (list.isEmpty) return OnlineStatus.unknown;
  return list.any((r) => r != ConnectivityResult.none)
      ? OnlineStatus.online
      : OnlineStatus.offline;
}

final connectivityChangesProvider = StreamProvider<OnlineStatus>((ref) async* {
  final conn = Connectivity();

  // initial
  final first = await conn.checkConnectivity(); // v6: List<ConnectivityResult>
  yield _mapFromList(first);

  // stream
  yield* conn.onConnectivityChanged
      .map<OnlineStatus>(_mapFromList)
      .distinct();
}, name: 'connectivityChanges');

final isOnlineProvider = Provider<bool>((ref) {
  final av = ref.watch(connectivityChangesProvider);
  return av.maybeWhen(
    data: (s) => s == OnlineStatus.online,
    orElse: () => true, // оптимистично, чтобы не блокировать UI
  );
}, name: 'isOnline');

class NetworkPolicy {
  final Ref ref;
  NetworkPolicy(this.ref);

  bool get isOnline => ref.read(isOnlineProvider);

  /// Ждём до `timeout`, пока сеть появится. Ничего не возвращаем.
  Future<void> waitUntilOnline({Duration timeout = const Duration(seconds: 15)}) async {
    if (isOnline) return;

    final conn = Connectivity();

    // повторная быстрая проверка
    final current = await conn.checkConnectivity();
    if (_mapFromList(current) == OnlineStatus.online) return;

    // ждём первое событие online (или таймаут)
    try {
      await conn.onConnectivityChanged
          .firstWhere((list) => _mapFromList(list) == OnlineStatus.online)
          .timeout(timeout);
    } catch (_) {
      // таймаут/ошибка — просто выходим
    }
  }
}

final networkPolicyProvider =
    Provider<NetworkPolicy>((ref) => NetworkPolicy(ref), name: 'networkPolicy');

/// Инициализатор: при восстановлении сети просим SWR перезагрузить просроченные ключи.
final swrRefreshOnReconnectProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<OnlineStatus>>(connectivityChangesProvider, (prev, next) {
    final wasOnline = prev?.value == OnlineStatus.online;
    final nowOnline = next.value == OnlineStatus.online;
    if (!wasOnline && nowOnline) {
      final store = ref.read(swrStoreProvider);
      store.revalidateAllIfNeeded();
    }
  });
  return;
}, name: 'swrRefreshOnReconnect');

