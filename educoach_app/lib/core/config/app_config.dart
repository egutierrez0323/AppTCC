import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const configured = String.fromEnvironment('EDUCOACH_API_URL');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://localhost:5100';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5100',
      _ => 'http://localhost:5100',
    };
  }
}
