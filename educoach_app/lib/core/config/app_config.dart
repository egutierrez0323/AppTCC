import 'package:flutter/foundation.dart';

class AppConfig {
  static const _productionApiBaseUrl = 'https://apptcc.onrender.com';

  static String get apiBaseUrl {
    const configured = String.fromEnvironment('EDUCOACH_API_URL');
    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }

    if (kReleaseMode) {
      return _productionApiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5100';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5100',
      _ => 'http://localhost:5100',
    };
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
