import 'package:flutter/foundation.dart';

/// Configuração do endereço da API CARCINUTRI.
///
/// Em desenvolvimento local, o backend roda em http://localhost:8000.
/// - Web/desktop: localhost funciona.
/// - Emulador Android: a máquina host é acessada por 10.0.2.2.
/// - Aparelho físico: use o IP da máquina na rede local.
class ApiConfig {
  static const String _hostWeb = 'localhost';
  static const int _porta = 8000;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$_hostWeb:$_porta';
    }
    // Emulador Android (Android Studio) acessa o host por 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_porta';
    }
    return 'http://$_hostWeb:$_porta';
  }
}
