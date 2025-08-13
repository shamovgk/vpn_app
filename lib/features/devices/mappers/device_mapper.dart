// lib/features/devices/mappers/device_mapper.dart
import '../models/dto/device_dto.dart';
import '../models/domain/device.dart';

Device deviceFromDto(DeviceDto dto) => Device(
  id: dto.id,
  token: dto.deviceToken,
  model: dto.deviceModel,
  os: dto.deviceOS,
  lastSeenUtc: dto.lastSeen,
);

DeviceDto deviceToDto(Device d) => DeviceDto(
  id: d.id,
  deviceToken: d.token,
  deviceModel: d.model,
  deviceOS: d.os,
  lastSeen: d.lastSeenUtc,
);
