// lib/features/devices/providers/device_controller.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import '../../../core/errors/ui_error.dart';
import '../models/domain/device.dart';
import '../usecases/fetch_devices_usecase.dart';
import '../usecases/refresh_devices_usecase.dart';
import '../usecases/add_current_device_usecase.dart';
import '../usecases/remove_device_usecase.dart';
import '../usecases/update_current_last_seen_usecase.dart';

typedef DeviceState = FeatureState<List<Device>>;

class DeviceController extends StateNotifier<DeviceState> {
  final FetchDevicesUseCase _fetch;
  final RefreshDevicesUseCase _refresh;
  final AddCurrentDeviceUseCase _addCurrent;
  final RemoveDeviceUseCase _remove;
  final UpdateCurrentLastSeenUseCase _updateLastSeen;

  CancelToken? _ct;

  DeviceController(
    this._fetch,
    this._refresh,
    this._addCurrent,
    this._remove,
    this._updateLastSeen,
  ) : super(const FeatureLoading());

  void bind(Ref ref) {
    // вызывать сразу после создания в провайдере
    ref.onDispose(_cancelActive);
  }

  CancelToken _replaceToken() {
    _ct?.cancel('devices:replaced');
    final t = CancelToken();
    _ct = t;
    return t;
  }

  void _cancelActive() {
    final t = _ct;
    if (t != null && !t.isCancelled) t.cancel('devices:dispose');
    _ct = null;
  }

  Future<void> load({bool force = false}) async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      final list = await _fetch.call(force: force, cancelToken: ct);
      state = FeatureReady<List<Device>>(list);
    } catch (e) {
      if (!ct.isCancelled) state = FeatureError<List<Device>>(presentableError(e));
    }
  }

  Future<void> pullToRefresh() async {
    final ct = _replaceToken();
    try {
      final list = await _refresh.call(cancelToken: ct);
      state = FeatureReady<List<Device>>(list);
    } catch (e) {
      if (!ct.isCancelled) state = FeatureError<List<Device>>(presentableError(e));
    }
  }

  Future<void> addCurrent() async {
    final ct = _replaceToken();
    try {
      await _addCurrent.call(cancelToken: ct);
      await pullToRefresh();
    } catch (e) {
      if (!ct.isCancelled) state = FeatureError<List<Device>>(presentableError(e));
    }
  }

  Future<void> removeByToken(String token) async {
    final ct = _replaceToken();
    try {
      await _remove.call(token, cancelToken: ct);
      await pullToRefresh();
    } catch (e) {
      if (!ct.isCancelled) state = FeatureError<List<Device>>(presentableError(e));
    }
  }

  Future<void> touchLastSeen() async {
    final ct = _replaceToken();
    try {
      await _updateLastSeen.call(cancelToken: ct);
      await pullToRefresh();
    } catch (e) {
      if (!ct.isCancelled) state = FeatureError<List<Device>>(presentableError(e));
    }
  }
}

