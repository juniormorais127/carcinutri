import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/usuario.dart';
import 'api_config.dart';

/// Erro de autenticação com mensagem amigável para exibir no app.
class AuthException implements Exception {
  final String mensagem;
  AuthException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Resposta do login: token + usuário.
class ResultadoLogin {
  final String token;
  final UsuarioLogado usuario;
  const ResultadoLogin({required this.token, required this.usuario});
}

/// Cliente HTTP da API de autenticação CARCINUTRI (espelha o padrão MareApi).
class AuthApi {
  static String get base => ApiConfig.baseUrl;

  final http.Client _http;
  AuthApi({http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  /// Cadastra um novo usuário e já retorna token + usuário logado.
  Future<ResultadoLogin> registrar({
    required String email,
    required String senha,
    required String nome,
    required PerfilUsuario perfil,
    String? telefone,
    String? cidade,
    String? regiao,
  }) async {
    final body = jsonEncode({
      'email': email,
      'senha': senha,
      'nome': nome,
      'role': perfil.name,
      'telefone': telefone,
      'cidade': cidade,
      'regiao': regiao,
    });
    final r = await _http.post(
      Uri.parse('$base/auth/register'),
      headers: _headers,
      body: body,
    );
    final j = _decodificar(r);
    // O backend retorna o usuário criado (sem token). Faz login em seguida.
    if (r.statusCode == 201 || r.statusCode == 200) {
      return login(email: email, senha: senha);
    }
    throw AuthException(_mensagemErro(j, r));
  }

  /// Entra com email + senha e retorna token + usuário.
  Future<ResultadoLogin> login({
    required String email,
    required String senha,
  }) async {
    final r = await _http.post(
      Uri.parse('$base/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeQueryComponent(email)}'
          '&password=${Uri.encodeQueryComponent(senha)}',
    );
    final j = _decodificar(r);
    if (r.statusCode != 200) {
      throw AuthException(_mensagemErro(j, r));
    }
    return ResultadoLogin(
      token: j['access_token'] as String,
      usuario: UsuarioLogado.fromJson(
          (j['user'] as Map).cast<String, dynamic>()),
    );
  }

  /// Consulta o usuário autenticado pelo token (valida a sessão persistida).
  Future<UsuarioLogado> me(String token) async {
    final r = await _http.get(
      Uri.parse('$base/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final j = _decodificar(r);
    if (r.statusCode != 200) {
      throw AuthException(_mensagemErro(j, r));
    }
    return UsuarioLogado.fromJson(j.cast<String, dynamic>());
  }

  /// Reenvia o e-mail de confirmação de conta.
  Future<void> reenviarVerificacao({required String email}) =>
      _postJson('/auth/reenviar-verificacao', {'email': email});

  /// Envia o link de recuperação de senha ("esqueci minha senha").
  Future<void> esqueciSenha({required String email}) =>
      _postJson('/auth/esqueci-senha', {'email': email});

  /// Redefine a senha usando o token recebido por e-mail.
  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
  }) =>
      _postJson('/auth/redefinir-senha', {
        'token': token,
        'nova_senha': novaSenha,
      });

  Future<void> _postJson(String caminho, Map<String, dynamic> body) async {
    final r = await _http.post(
      Uri.parse('$base$caminho'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final j = _decodificar(r);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw AuthException(_mensagemErro(j, r));
    }
  }

  Map<String, dynamic> _decodificar(http.Response r) {
    if (r.body.isEmpty) return {};
    try {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _mensagemErro(Map<String, dynamic> j, http.Response r) {
    final det = j['detail'];
    if (det is String && det.isNotEmpty) return det;
    return 'Falha na conexão (HTTP ${r.statusCode}).';
  }
}
