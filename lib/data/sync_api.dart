import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/modelos.dart';
import '../domain/servico.dart';
import 'api_config.dart';

/// Cliente HTTP dos endpoints de sync (offline-first) da API CARCINUTRI.
///
/// Envia lotes de registros pendentes para o servidor, escopados ao usuário
/// autenticado (via Bearer token). O id de cada registro é o UUID gerado no
/// aparelho; o servidor faz upsert.
class SyncApi {
  static String get base => ApiConfig.baseUrl;

  final http.Client _http;
  SyncApi({http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> _enviar(String rota, String token, List<Map<String, dynamic>> itens) async {
    if (itens.isEmpty) return;
    final r = await _http.post(
      Uri.parse('$base/sync/$rota'),
      headers: _headers(token),
      body: jsonEncode(itens),
    );
    if (r.statusCode != 200) {
      throw Exception('Sync $rota falhou (HTTP ${r.statusCode})');
    }
  }

  Future<void> viveiros(String token, List<Viveiro> itens) => _enviar(
        'viveiros',
        token,
        itens
            .map((v) => {
                  'id': v.id,
                  'fazenda_id': null,
                  'nome': v.nome,
                  'area_ha': v.areaHa,
                  'densidade_padrao': v.densidadePadrao,
                  'marca_racao': v.marcaRacao,
                  'data_povoamento': v.dataPovoamento == null
                      ? null
                      : _dataIso(v.dataPovoamento!),
                  'criado_em': v.criadoEm.toIso8601String(),
                })
            .toList(),
      );

  Future<void> biometrias(String token, List<Biometria> itens) => _enviar(
        'biometrias',
        token,
        itens
            .map((b) => {
                  'id': b.id,
                  'viveiro_id': b.viveiroId,
                  'data': _dataIso(b.data),
                  'peso_amostra_kg': b.pesoAmostraKg,
                  'n_amostrado': b.nAmostrado,
                  'peso_medio': b.pesoMedio,
                  'criado_em': b.data.toIso8601String(),
                })
            .toList(),
      );

  Future<void> qualidadeAgua(String token, List<QualidadeAgua> itens) =>
      _enviar(
        'qualidade-agua',
        token,
        itens
            .map((q) => {
                  'id': q.id,
                  'viveiro_id': q.viveiroId,
                  'data': _dataIso(q.data),
                  'od': q.od,
                  'ph': q.ph,
                  'temperatura': q.temperatura,
                  'amonia': q.amonia,
                  'nitrito': q.nitrito,
                  'alcalinidade': q.alcalinidade,
                  'criado_em': q.data.toIso8601String(),
                })
            .toList(),
      );

  Future<void> calculos(String token, List<Calculo> itens) => _enviar(
        'calculos',
        token,
        itens
            .map((c) => {
                  'id': c.id,
                  'viveiro_id': c.viveiroId,
                  'tipo': c.tipo.name,
                  'entradas': c.entradas,
                  'resultado': c.resultado,
                  'criado_em': c.criadoEm.toIso8601String(),
                })
            .toList(),
      );

  Future<void> solicitacoes(String token, List<SolicitacaoServico> itens) =>
      _enviar(
        'servicos',
        token,
        itens
            .map((s) => {
                  'id': s.id,
                  'titulo': s.titulo,
                  'descricao': s.descricao,
                  'categoria': s.categoria,
                  'cidade': s.cidade,
                  'valor_estimado': s.valorEstimado,
                  'status': s.status,
                  'criado_em': s.criadoEm.toIso8601String(),
                })
            .toList(),
      );

  static String _dataIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
