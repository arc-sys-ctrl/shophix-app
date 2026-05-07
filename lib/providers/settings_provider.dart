import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final settingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ApiService().fetchPublicSettings();
});

