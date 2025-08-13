// lib/features/devices/models/dto/device_dto.dart
import '../domain/device.dart';

class DeviceDto {
  final int id;
  final String deviceToken;
  final String deviceModel;
  final String deviceOS;
  final String? lastSeen;

  const DeviceDto({
    required this.id,
    required this.deviceToken,
    required this.deviceModel,
    required this.deviceOS,
    this.lastSeen,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    return DeviceDto(
      id: id,
      deviceToken: (json['device_token'] ?? '').toString(),
      deviceModel: (json['device_model'] ?? 'Unknown Model').toString(),
      deviceOS: (json['device_os'] ?? 'Unknown OS').toString(),
      lastSeen: json['last_seen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_token': deviceToken,
    'device_model': deviceModel,
    'device_os': deviceOS,
    'last_seen': lastSeen,
  };
}

extension DeviceDtoMapping on DeviceDto {
  Device toDomain() => Device(
    id: id,
    token: deviceToken,
    model: deviceModel,
    os: deviceOS,
    lastSeenUtc: lastSeen,
  );
}
