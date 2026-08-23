import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente da API Tábua de Maré (tabuamare.api.br).
///
/// Acesso **anônimo** (sem chave): 16 req/min e cota mensal ilimitada. Para
/// conter o uso, o app busca o **mês inteiro em uma única requisição** e
/// cacheia o resultado localmente, evitando refetch dentro do mesmo mês —
/// cerca de 1 requisição por porto/mês, muito abaixo de qualquer limite.
class PortoMare {
  final String id;
  final String nome;
  const PortoMare({required this.id, required this.nome});
}

/// Um nível de maré num instante (hora + altura em metros).
class NivelMare {
  final DateTime tempo;
  final double nivelM;
  const NivelMare({required this.tempo, required this.nivelM});
}

/// Preamar ou baixa-mar num instante, inferidos dos níveis do dia.
class EventoRealMare {
  final DateTime tempo;
  final double nivelM;
  final bool preamar;
  const EventoRealMare({
    required this.tempo,
    required this.nivelM,
    required this.preamar,
  });
}

/// Maré de um dia: níveis (curva) + eventos (preamar/baixa).
class DiaMareApi {
  final DateTime dia;
  final List<NivelMare> niveis;
  final List<EventoRealMare> eventos;
  const DiaMareApi({
    required this.dia,
    required this.niveis,
    required this.eventos,
  });
}

/// Resultado da busca de um mês: dias parseados + JSON bruto (p/ cache).
class ResultadoTabua {
  final Map<int, DiaMareApi> dias;
  final Map<String, dynamic> raw;
  const ResultadoTabua({required this.dias, required this.raw});
}

/// Cliente HTTP da Tábua de Maré API (acesso anônimo).
class MareApi {
  static const String base = 'https://tabuamare.api.br';

  final http.Client _http;
  MareApi({http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> get _headers => {'Accept': 'application/json'};

  Uri _get(String path) => Uri.parse('$base$path');

  /// Lista de estados costeiros (siglas minúsculas).
  Future<List<String>> estados() async {
    final r = await _http.get(_get('/api/v2/states'), headers: _headers);
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['data'] as List).cast<String>();
  }

  /// Portos de um estado.
  Future<List<PortoMare>> portos(String estado) async {
    final r =
        await _http.get(_get('/api/v2/harbor_names/$estado'), headers: _headers);
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['data'] as List)
        .map((e) => PortoMare(
              id: (e as Map<String, dynamic>)['id'] as String,
              nome: e['harbor_name'] as String,
            ))
        .toList();
  }

  /// Busca a tábua do mês inteiro (uma única requisição) do porto.
  ///
  /// O servidor expande `[1-31]` e dedup os dias. Consome **1** requisição
  /// por porto/mês — bem abaixo da cota diária de 800 e mensal de 32 mil.
  Future<ResultadoTabua> tabuaMes(String portoId, int ano, int mes) async {
    final r = await _http.get(
      _get('/api/v2/tabua-mare/$portoId/$mes/[1-31]'),
      headers: _headers,
    );
    if (r.statusCode != 200) {
      throw Exception('Tábua de Maré falhou (HTTP ${r.statusCode})');
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return ResultadoTabua(dias: parseTabua(j, ano, mes), raw: j);
  }
}

/// Converte o JSON da tábua em [DiaMareApi] por dia do mês.
Map<int, DiaMareApi> parseTabua(Map<String, dynamic> j, int ano, int mes) {
  final dados = j['data'] as List?;
  if (dados == null || dados.isEmpty) return {};
  final harbor = dados.first as Map<String, dynamic>;
  final months = harbor['months'] as List?;
  if (months == null || months.isEmpty) return {};
  final dias = (months.first as Map<String, dynamic>)['days'] as List?;
  if (dias == null) return {};

  final result = <int, DiaMareApi>{};
  for (final d in dias) {
    final dm = d as Map<String, dynamic>;
    final diaNum = (dm['day'] as num).toInt();
    final horas = (dm['hours'] as List? ?? [])
        .map((h) {
          final hm = h as Map<String, dynamic>;
          final partes = (hm['hour'] as String).split(':');
          final tempo = DateTime(ano, mes, diaNum, int.parse(partes[0]),
              int.parse(partes[1]));
          return NivelMare(
              tempo: tempo, nivelM: (hm['level'] as num).toDouble());
        })
        .toList()
      ..sort((a, b) => a.tempo.compareTo(b.tempo));
    result[diaNum] = DiaMareApi(
      dia: DateTime(ano, mes, diaNum),
      niveis: horas,
      eventos: _extrairEventos(horas),
    );
  }
  return result;
}

/// Marca picos como preamar e vales como baixa-mar por análise local.
///
/// Pontas comparam apenas contra o único vizinho; pontos intermediários usam
/// extremos locais (maior que os dois vizinhos → preamar; menor → baixa-mar).
List<EventoRealMare> _extrairEventos(List<NivelMare> h) {
  final ev = <EventoRealMare>[];
  if (h.isEmpty) return ev;
  for (var i = 0; i < h.length; i++) {
    final v = h[i].nivelM;
    final isFirst = i == 0;
    final isLast = i == h.length - 1;
    final prev = isFirst ? null : h[i - 1].nivelM;
    final next = isLast ? null : h[i + 1].nivelM;

    bool? preamar;
    if (isFirst && next != null) {
      preamar = v > next; // ponta inicial: sobe → preamar, desce → baixa
    } else if (isLast && prev != null) {
      preamar = v > prev; // ponta final
    } else if (prev != null && next != null) {
      if (v >= prev && v >= next) {
        preamar = true;
      } else if (v <= prev && v <= next) {
        preamar = false;
      }
    }
    if (preamar != null) {
      ev.add(EventoRealMare(tempo: h[i].tempo, nivelM: v, preamar: preamar));
    }
  }
  return ev;
}
