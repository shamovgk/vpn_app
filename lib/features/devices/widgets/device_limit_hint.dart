// lib/features/devices/widgets/device_limit_hint.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import 'package:vpn_app/features/auth/providers/auth_providers.dart';
import 'package:vpn_app/features/devices/models/domain/device.dart';
import 'package:vpn_app/features/devices/providers/device_providers.dart';

class DeviceLimitHint extends ConsumerWidget {
  final int maxDevices;
  const DeviceLimitHint({super.key, this.maxDevices = 3});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.tokens;

    final isAuth = ref.watch(isAuthenticatedProvider);
    if (!isAuth) return const SizedBox.shrink();

    final devicesState = ref.watch(deviceControllerProvider);
    final tokenAsync = ref.watch(currentDeviceTokenProvider);

    return tokenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (currentToken) {
        if (devicesState is! FeatureReady<List<Device>>) return const SizedBox.shrink();
        final devices = devicesState.data;
        final hasCurrent = devices.any((d) => d.token == currentToken);
        final overLimit = devices.length >= maxDevices && !hasCurrent;

        if (!overLimit) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: t.spacing.all(t.spacing.sm),
          decoration: BoxDecoration(
            color: c.bgLight,
            borderRadius: t.radii.brMd,
            border: Border.all(color: c.borderMuted),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: c.warning),
              SizedBox(width: t.spacing.xs),
              Expanded(
                child: Text(
                  'Достигнут лимит устройств. Выйдите из аккаунта на одном из устройств, затем повторите вход здесь.',
                  style: t.typography.bodySm.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
