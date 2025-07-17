class ApiError implements Exception {
  final String message;
  final int? code;

  ApiError(this.message, {this.code});

  @override
  String toString() => message;
}
