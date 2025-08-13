// lib/core/cache/swr/swr_keys.dart
abstract class SwrKeys {
  static const devices = 'devices';
  static const subscription = 'subscription';
  static String deviceById(int id) => 'device:$id';
}