// lib/core/models/feature_state.dart
sealed class FeatureState<T> {
  const FeatureState();
}

class FeatureIdle<T> extends FeatureState<T> {
  const FeatureIdle();
}

class FeatureLoading<T> extends FeatureState<T> {
  const FeatureLoading();
}

class FeatureReady<T> extends FeatureState<T> {
  final T data;
  const FeatureReady(this.data);
}

class FeatureError<T> extends FeatureState<T> {
  final String message;
  const FeatureError(this.message);
}

// Удобные геттеры для UI
extension FeatureStateX<T> on FeatureState<T> {
  bool get isLoading => this is FeatureLoading<T>;
  T? get dataOrNull => this is FeatureReady<T> ? (this as FeatureReady<T>).data : null;
  String? get errorMessage => this is FeatureError<T> ? (this as FeatureError<T>).message : null;
}
