// lib/features/vpn/mappers/vpn_mapper.dart
import 'package:vpn_app/features/vpn/models/vpn_config.dart';

import '../models/dto/vpn_config_dto.dart';

VpnConfig vpnConfigFromDto(VpnConfigDto dto) => VpnConfig(
  privateKey: dto.privateKey,
  address: dto.address,
  dns: dto.dns ?? '1.1.1.1',
  serverPublicKey: dto.serverPublicKey,
  endpoint: dto.endpoint,
  allowedIps: dto.allowedIps ?? '0.0.0.0/0, ::/0',
);
