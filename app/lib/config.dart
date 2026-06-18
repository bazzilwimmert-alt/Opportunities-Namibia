import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  // Base URL of the Bax backend API.
  // Override at build/run time with: --dart-define=BAX_API_BASE=https://api.yourhost
  static const String _override = String.fromEnvironment('BAX_API_BASE');

  static String get apiBase {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:4000';
    try {
      // Android emulator reaches host machine via 10.0.2.2
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {}
    return 'http://localhost:4000';
  }
}
