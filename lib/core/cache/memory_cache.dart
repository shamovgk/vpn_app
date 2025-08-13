// lib/core/cache/memory_cache.dart
class MemoryCache<T> {
  T? _value;
  DateTime? _ts;

  T? get value => _value;
  DateTime? get timestamp => _ts;
  bool get hasValue => _value != null;

  void set(T v) {
    _value = v;
    _ts = DateTime.now();
  }

  void clear() {
    _value = null;
    _ts = null;
  }

  bool isStale(Duration maxAge) {
    if (_ts == null) return true;
    return DateTime.now().difference(_ts!) > maxAge;
  }

  void markStale() {
    if (_value == null) return;
    _ts = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
