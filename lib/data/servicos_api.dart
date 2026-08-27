import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/servico.dart';
import 'api_config.dart';

/// Erro em operações de serviços e contratos com mensagem amigável para exibição.
class ServicosException implements Exception {
  final String mensagem;
  ServicosException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Cliente HTTP para a API de Serviços, Marketplace, Custódia e Chat.
class ServicosApi {
  static String get base => ApiConfig.baseUrl;

  final http.Client _http;
  ServicosApi({http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Lista solicitações de serviços abertas no marketplace.
  Future<List<SolicitacaoServico>> listarAbertos(
    String token, {
    String? categoria,
    String? cidade,
  }) async {
    final params = <String, String>{};
    if (categoria != null && categoria.isNotEmpty) params['categoria'] = categoria;
    if (cidade != null && cidade.isNotEmpty) params['cidade'] = cidade;

    final uri = Uri.parse('$base/servicos').replace(queryParameters: params.isEmpty ? null : params);
    final r = await _http.get(uri, headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    final list = jsonDecode(r.body) as List;
    return list.map((e) => SolicitacaoServico.fromJson(Map<String, Object?>.from(e as Map))).toList();
  }

  /// Lista as solicitações do usuário produtor logado.
  Future<List<SolicitacaoServico>> meusServicos(String token) async {
    final r = await _http.get(Uri.parse('$base/servicos/meus'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    final list = jsonDecode(r.body) as List;
    return list.map((e) => SolicitacaoServico.fromJson(Map<String, Object?>.from(e as Map))).toList();
  }

  /// Cria uma solicitação de serviço online diretamente.
  Future<SolicitacaoServico> criarSolicitacao(
    String token, {
    required String titulo,
    String? descricao,
    String? categoria,
    String? cidade,
    required double valorEstimado,
  }) async {
    final body = jsonEncode({
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'cidade': cidade,
      'valor_estimado': valorEstimado,
    });
    final r = await _http.post(Uri.parse('$base/servicos'), headers: _headers(token), body: body);
    final j = _decodificar(r);
    if (r.statusCode < 200 || r.statusCode >= 300) throw ServicosException(_mensagemErro(j, r));

    return SolicitacaoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Detalhes de uma solicitação de serviço.
  Future<SolicitacaoServico> obterServico(String token, String servicoId) async {
    final r = await _http.get(Uri.parse('$base/servicos/$servicoId'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return SolicitacaoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Lista as propostas de uma solicitação.
  Future<List<PropostaServico>> listarPropostas(String token, String servicoId) async {
    final r = await _http.get(Uri.parse('$base/servicos/$servicoId/propostas'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    final list = jsonDecode(r.body) as List;
    return list.map((e) => PropostaServico.fromJson(Map<String, Object?>.from(e as Map))).toList();
  }

  /// Cria ou atualiza proposta de um técnico.
  Future<PropostaServico> criarProposta(
    String token,
    String servicoId, {
    required double valor,
    String? mensagem,
  }) async {
    final body = jsonEncode({
      'valor': valor,
      'mensagem': mensagem,
    });
    final r = await _http.post(
      Uri.parse('$base/servicos/$servicoId/propostas'),
      headers: _headers(token),
      body: body,
    );
    final j = _decodificar(r);
    if (r.statusCode < 200 || r.statusCode >= 300) throw ServicosException(_mensagemErro(j, r));

    return PropostaServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Produtor aceita uma proposta -> gera contrato.
  Future<ContratoServico> aceitarProposta(
    String token,
    String servicoId,
    String propostaId,
  ) async {
    final r = await _http.post(
      Uri.parse('$base/servicos/$servicoId/propostas/$propostaId/aceitar'),
      headers: _headers(token),
    );
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return ContratoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Lista contratos onde o usuário é produtor ou técnico.
  Future<List<ContratoServico>> meusContratos(String token) async {
    final r = await _http.get(Uri.parse('$base/contratos/meus'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    final list = jsonDecode(r.body) as List;
    return list.map((e) => ContratoServico.fromJson(Map<String, Object?>.from(e as Map))).toList();
  }

  /// Detalhes de um contrato.
  Future<ContratoServico> obterContrato(String token, String contratoId) async {
    final r = await _http.get(Uri.parse('$base/contratos/$contratoId'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return ContratoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Simula pagamento em custódia (produtor).
  Future<ContratoServico> pagarContrato(String token, String contratoId) async {
    final r = await _http.post(Uri.parse('$base/contratos/$contratoId/pagar'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return ContratoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Finaliza serviço (técnico).
  Future<ContratoServico> finalizarServico(String token, String contratoId) async {
    final r = await _http.post(Uri.parse('$base/contratos/$contratoId/finalizar'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return ContratoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Aprova serviço e repassa pagamento (produtor).
  Future<ContratoServico> aprovarServico(String token, String contratoId) async {
    final r = await _http.post(Uri.parse('$base/contratos/$contratoId/aprovar'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return ContratoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Rejeita serviço e restitui pagamento (produtor).
  Future<ContratoServico> rejeitarServico(String token, String contratoId) async {
    final r = await _http.post(Uri.parse('$base/contratos/$contratoId/rejeitar'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    return ContratoServico.fromJson(Map<String, Object?>.from(j));
  }

  /// Lista mensagens do chat do contrato (exige comunicação liberada).
  Future<List<MensagemServico>> listarMensagens(String token, String contratoId) async {
    final r = await _http.get(Uri.parse('$base/contratos/$contratoId/mensagens'), headers: _headers(token));
    final j = _decodificar(r);
    if (r.statusCode != 200) throw ServicosException(_mensagemErro(j, r));

    final list = jsonDecode(r.body) as List;
    return list.map((e) => MensagemServico.fromJson(Map<String, Object?>.from(e as Map))).toList();
  }

  /// Envia mensagem no chat do contrato.
  Future<MensagemServico> enviarMensagem(String token, String contratoId, String texto) async {
    final body = jsonEncode({'texto': texto});
    final r = await _http.post(
      Uri.parse('$base/contratos/$contratoId/mensagens'),
      headers: _headers(token),
      body: body,
    );
    final j = _decodificar(r);
    if (r.statusCode < 200 || r.statusCode >= 300) throw ServicosException(_mensagemErro(j, r));

    return MensagemServico.fromJson(Map<String, Object?>.from(j));
  }

  Map<String, dynamic> _decodificar(http.Response r) {
    if (r.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  String _mensagemErro(Map<String, dynamic> j, http.Response r) {
    final det = j['detail'];
    if (det is String && det.isNotEmpty) return det;
    return 'Falha na conexão com o servidor (HTTP ${r.statusCode}).';
  }
}
