// lib/features/devices/widgets/device_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import 'package:vpn_app/features/devices/models/domain/device.dart';
import 'package:vpn_app/features/devices/providers/device_providers.dart';

class DeviceSummary extends ConsumerStatefulWidget {
  final int maxDevices;
  final bool autoLoad;

  const DeviceSummary({
    super.key,
    this.maxDevices = 3,
    this.autoLoad = true,
  });

  @override
  ConsumerState<DeviceSummary> createState() => _DeviceSummaryState();
}

class _DeviceSummaryState extends ConsumerState<DeviceSummary> {
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      Future.microtask(() {
        if (!_loadedOnce) {
          ref.read(deviceControllerProvider.notifier).load();
          _loadedOnce = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;
    final state = ref.watch(deviceControllerProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: () {
        if (state is FeatureLoading) {
          return const SizedBox(
            key: ValueKey('loading'),
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (state is FeatureReady<List<Device>>) {
          final devices = state.data;
          return Text(
            key: const ValueKey('loaded'),
            'Устройства: ${devices.length}/${widget.maxDevices}',
            style: t.typography.bodySm.copyWith(color: c.textMuted),
          );
        }
        return Text(
          key: const ValueKey('error'),
          'Устройства: —',
          style: t.typography.bodySm.copyWith(color: c.textMuted),
        );
      }(),
    );
  }
}

