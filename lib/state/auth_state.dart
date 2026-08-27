import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_api.dart';
import '../domain/usuario.dart';

/// Estado de autenticação: quem está logado e o token da sessão.
///
/// A sessão é persistida no aparelho (SharedPreferences) para o usuário não
/// precisar logar de novo a cada abertura — importante no uso offline.
class AuthState extends ChangeNotifier {
  static const _chaveToken = 'auth_token';
  static const _chaveUsuario = 'auth_usuario';

  final AuthApi _api;

  UsuarioLogado? _usuario;
  String? _token;
  bool _carregado = false;

  AuthState({AuthApi? api}) : _api = api ?? AuthApi();

  UsuarioLogado? get usuario => _usuario;
  String? get token => _token;
  bool get autenticado => _token != null && _usuario != null;
  bool get carregado => _carregado;

  /// Restaura a sessão salva no aparelho (offline-first: não exige rede).
  Future<void> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_chaveToken);
    final json = prefs.getString(_chaveUsuario);
    if (token != null && json != null) {
      _token = token;
      _usuario = UsuarioLogado.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    }
    _carregado = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String senha}) async {
    final r = await _api.login(email: email, senha: senha);
    await _salvarSessao(r.token, r.usuario);
  }

  Future<void> registrar({
    required String email,
    required String senha,
    required String nome,
    required PerfilUsuario perfil,
    String? telefone,
    String? cidade,
    String? regiao,
  }) async {
    final r = await _api.registrar(
      email: email,
      senha: senha,
      nome: nome,
      perfil: perfil,
      telefone: telefone,
      cidade: cidade,
      regiao: regiao,
    );
    await _salvarSessao(r.token, r.usuario);
  }

  /// Reenvia o e-mail de confirmação para o usuário atual.
  Future<void> reenviarVerificacao() async {
    final email = _usuario?.email;
    if (email == null) return;
    await _api.reenviarVerificacao(email: email);
  }

  /// Solicita o link de recuperação de senha para um e-mail.
  Future<void> esqueciSenha({required String email}) =>
      _api.esqueciSenha(email: email);

  /// Redefine a senha com o token recebido por e-mail.
  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
  }) =>
      _api.redefinirSenha(token: token, novaSenha: novaSenha);

  /// Marca localmente o e-mail como verificado (após "Já confirmei").
  Future<void> marcarEmailVerificado() async {
    final u = _usuario;
    if (u == null || u.emailVerificado) return;
    await _salvarSessao(_token!, u.copiar(emailVerificado: true));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveToken);
    await prefs.remove(_chaveUsuario);
    _token = null;
    _usuario = null;
    notifyListeners();
  }

  Future<void> _salvarSessao(String token, UsuarioLogado usuario) async {
    _token = token;
    _usuario = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
    await prefs.setString(_chaveUsuario, jsonEncode(usuario.toJson()));
    notifyListeners();
  }
}
