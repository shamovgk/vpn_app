// lib/core/cache/swr/swr_store.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memory_cache.dart';

class SwrEntry<T> {
  SwrEntry({
    required this.key,
    required this.fetcher,
    required this.ttl,
    this.revalidateOnResume = true,
  });

  final String key;
  final Future<T> Function() fetcher;
  final Duration ttl;
  final bool revalidateOnResume;

  final MemoryCache<T> _cache = MemoryCache<T>();
  bool get hasValue => _cache.value != null;
  T? get value => _cache.value;

  Future<T> get({bool forceRefresh = false}) async {
    final cached = _cache.value;
    final fresh = cached != null && !_cache.isStale(ttl);

    if (!forceRefresh && fresh) {
      unawaited(_safeRefresh());
      return cached as T;
    }
    return refresh();
  }

  Future<T> refresh() async {
    final v = await fetcher();
    _cache.set(v);
    return v;
  }

  void touch() {
    _cache.markStale();
  }

  Future<void> _safeRefresh() async {
    try { await refresh(); } catch (_) {}
  }

  Future<void> revalidateIfNeeded() async {
    if (_cache.value != null && _cache.isStale(ttl)) {
      await _safeRefresh();
    }
  }

  void setOptimistic(T v) {
    _cache.set(v);
  }

  void mutate(T Function(T? current) updater, {bool revalidate = true}) {
    final next = updater(_cache.value);
    if (next != null) {
      _cache.set(next);
      if (revalidate) {
        unawaited(refresh());
      }
    }
  }
}

class SwrStore with WidgetsBindingObserver {
  SwrStore() {
    WidgetsBinding.instance.addObserver(this);
  }

  final Map<String, SwrEntry<dynamic>> _entries = {};

  Future<void> revalidateAllIfNeeded() async {
    for (final e in _entries.values) {
      if (e.revalidateOnResume) {
        unawaited(e.revalidateIfNeeded());
      }
    }
  }
  SwrEntry<T> register<T>({
    required String key,
    required Future<T> Function() fetcher,
    required Duration ttl,
    bool revalidateOnResume = true,
  }) {
    final existing = _entries[key];
    if (existing != null) return existing as SwrEntry<T>;
    final e = SwrEntry<T>(
      key: key,
      fetcher: fetcher,
      ttl: ttl,
      revalidateOnResume: revalidateOnResume,
    );
    _entries[key] = e;
    return e;
  }

  SwrEntry<T> entry<T>(String key) {
    final e = _entries[key];
    if (e == null) throw StateError('SwrEntry not found for key: $key');
    return e as SwrEntry<T>;
  }

  void touch(String key) {
    final e = _entries[key];
    e?.touch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      for (final e in _entries.values) {
        if (e.revalidateOnResume) {
          unawaited(e.revalidateIfNeeded());
        }
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entries.clear();
  }
}

final swrStoreProvider = Provider<SwrStore>((ref) {
  final store = SwrStore();
  ref.onDispose(store.dispose);
  return store;
}, name: 'swrStore');
