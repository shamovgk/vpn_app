// lib/features/vpn/models/dto/vpn_config_dto.dart
class VpnConfigDto {
  final String privateKey;
  final String address;
  final String? dns;
  final String serverPublicKey;
  final String endpoint;
  final String? allowedIps;

  const VpnConfigDto({
    required this.privateKey,
    required this.address,
    this.dns,
    required this.serverPublicKey,
    required this.endpoint,
    this.allowedIps,
  });

  factory VpnConfigDto.fromJson(Map<String, dynamic> json) {
    return VpnConfigDto(
      privateKey: json['privateKey'] as String,
      address: json['address'] as String,
      dns: json['dns'] as String?,
      serverPublicKey: json['serverPublicKey'] as String,
      endpoint: json['endpoint'] as String,
      allowedIps: json['allowedIps'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'privateKey': privateKey,
    'address': address,
    'dns': dns,
    'serverPublicKey': serverPublicKey,
    'endpoint': endpoint,
    'allowedIps': allowedIps,
  };
}
