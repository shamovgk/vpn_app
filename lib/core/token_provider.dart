import 'package:flutter_riverpod/flutter_riverpod.dart';

// Всегда актуальный токен для API-запросов
final tokenProvider = StateProvider<String?>((ref) => null);