// lib/features/devices/models/domain/device.dart
import 'package:flutter/foundation.dart';

@immutable
class Device {
  final int id;
  final String token;
  final String model;
  final String os;
  final String? lastSeenUtc;

  const Device({
    required this.id,
    required this.token,
    required this.model,
    required this.os,
    this.lastSeenUtc,
  });
}
