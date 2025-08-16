// lib/features/subscription/providers/subscription_controller.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/errors/ui_error.dart';
import 'package:vpn_app/features/subscription/providers/subscription_providers.dart';
import '../models/subscription_state.dart';
import '../repositories/subscription_repository.dart';

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>(
  (ref) {
    final ctrl = SubscriptionController(ref.watch(subscriptionRepositoryProvider));
    ctrl.bind(ref);
    return ctrl;
  },
  name: 'subscriptionController',
);

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController(this._repo) : super(const SubscriptionIdle());

  final SubscriptionRepository _repo;
  CancelToken? _ct;

  void bind(Ref ref) {
    ref.onDispose(_cancelActive);
  }

  CancelToken _replaceToken() {
    _ct?.cancel('subscription:replaced');
    final t = CancelToken();
    _ct = t;
    return t;
  }

  void _cancelActive() {
    final t = _ct;
    if (t != null && !t.isCancelled) t.cancel('subscription:dispose');
    _ct = null;
  }

  Future<void> fetch() async {
    final cached = _repo.getCached();
    if (cached != null) {
      state = SubscriptionReady(cached);
      if (!_repo.isCacheFresh()) {
        unawaited(_refresh());
      }
      return;
    }

    state = const SubscriptionLoading();
    await _refresh();
  }

  Future<void> _refresh() async {
    final ct = _replaceToken();
    try {
      final fresh = await _repo.fetchFresh(cancelToken: ct);
      if (!mounted || ct.isCancelled) return;
      state = SubscriptionReady(fresh);
    } catch (e) {
      if (!mounted || ct.isCancelled) return;
      if (state is! SubscriptionReady) {
        state = SubscriptionError(presentableError(e));
      }
    }
  }
}
