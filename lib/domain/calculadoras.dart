import 'dart:math' as math;

import 'modelos.dart';

/// Erro de validação lançado quando uma calculadora recebe entradas inválidas.
/// A mensagem é exibida diretamente ao usuário.
class CalculoInvalido implements Exception {
  final String mensagem;
  CalculoInvalido(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Um item do resultado exibido ao produtor.
class ItemResultado {
  final String rotulo;
  final String valor;
  final bool destaque;
  ItemResultado(this.rotulo, this.valor, {this.destaque = false});
}

/// Resultado completo de uma calculadora.
class ResultadoCalculo {
  final List<ItemResultado> itens;
  ResultadoCalculo(this.itens);

  ItemResultado? get principal {
    for (final i in itens) {
      if (i.destaque) return i;
    }
    return null;
  }
}

/// Definição de um campo de entrada de uma calculadora.
class CampoEntrada {
  final String id;
  final String rotulo;
  final String? unidade;

  /// Quando é `'area'` ou `'densidade'`, a tela tenta pré-preencher a partir
  /// do viveiro selecionado.
  final String? chaveViveiro;

  /// Valor sugerido (ex.: taxa padrão de arraçoamento = 5%).
  final double? valorPadrao;

  /// Campo de texto livre (ex.: marca da ração). Não entra no cálculo numérico.
  final bool texto;
  CampoEntrada({
    required this.id,
    required this.rotulo,
    this.unidade,
    this.chaveViveiro,
    this.valorPadrao,
    this.texto = false,
  });
}

/// Definição completa de uma calculadora (campos + função pura de cálculo).
class DefinicaoCalculadora {
  final TipoCalculadora tipo;
  final String titulo;
  final String descricao;
  final String icone;
  final List<CampoEntrada> campos;
  final ResultadoCalculo Function(Map<String, double> entradas) calcular;
  DefinicaoCalculadora({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.campos,
    required this.calcular,
  });
}

// ---------------------------------------------------------------------------
// Helpers de validação / formatação
// ---------------------------------------------------------------------------

double _req(Map<String, double> e, String id, String rotulo) {
  final v = e[id];
  if (v == null || v.isNaN) {
    throw CalculoInvalido('Informe "$rotulo".');
  }
  if (v < 0) {
    throw CalculoInvalido('"$rotulo" não pode ser negativo.');
  }
  return v;
}

double _pos(Map<String, double> e, String id, String rotulo) {
  final v = _req(e, id, rotulo);
  if (v == 0) {
    throw CalculoInvalido('"$rotulo" precisa ser maior que zero.');
  }
  return v;
}

String _fmt(double v, [int decimais = 2]) {
  final s = v.toStringAsFixed(decimais);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

double _arred(double v, [int decimais = 2]) {
  final f = math.pow(10, decimais).toDouble();
  return (v * f).round() / f;
}

// ---------------------------------------------------------------------------
// Funções derivadas reutilizáveis (painel do viveiro + calculadoras)
// ---------------------------------------------------------------------------

/// Biomassa estimada em kg:
/// densidade (cam/m²) × área (ha) × 10.000 m²/ha × pesoMédio (g) ÷ 1000.
double calcularBiomassa(
    double densidade, double areaHa, double pesoMedioG) {
  return densidade * areaHa * 10000 * pesoMedioG / 1000;
}

/// Ração diária em kg/dia = biomassa (kg) × taxa (%) / 100.
double racaoPorDia(double biomassaKg, double taxaPct) {
  return biomassaKg * taxaPct / 100;
}

// ---------------------------------------------------------------------------
// Funções de cálculo das 12 calculadoras
// ---------------------------------------------------------------------------

ResultadoCalculo _densidade(Map<String, double> e) {
  final n = _req(e, 'n_camaroes', 'Nº de camarões');
  final area = _pos(e, 'area', 'Área do viveiro (ha)');
  final densidade = n / (area * 10000);
  return ResultadoCalculo([
    ItemResultado('Camarões por m²', '${_fmt(densidade, 1)} cam/m²', destaque: true),
    ItemResultado('Nº de camarões', _fmt(n)),
    ItemResultado('Área do viveiro', '${_fmt(area)} ha'),
  ]);
}

ResultadoCalculo _povoamento(Map<String, double> e) {
  final area = _pos(e, 'area', 'Área do viveiro (ha)');
  final densidade = _pos(e, 'densidade', 'Densidade desejada (cam/m²)');
  final n = area * 10000 * densidade;
  return ResultadoCalculo([
    ItemResultado('Camarões a povoar', _fmt(n), destaque: true),
    ItemResultado('Área do viveiro', '${_fmt(area)} ha'),
    ItemResultado('Densidade desejada', '${_fmt(densidade, 1)} cam/m²'),
  ]);
}

ResultadoCalculo _sobrevivencia(Map<String, double> e) {
  final inicial = _pos(e, 'n_inicial', 'Nº inicial de camarões');
  final atual = _req(e, 'n_atual', 'Nº atual/final de camarões');
  final pct = atual / inicial * 100;
  return ResultadoCalculo([
    ItemResultado('Sobrevivência', '${_fmt(pct, 1)}%', destaque: true),
    ItemResultado('Nº inicial', _fmt(inicial)),
    ItemResultado('Nº atual', _fmt(atual)),
  ]);
}

ResultadoCalculo _pesoMedio(Map<String, double> e) {
  final pesoKg = _pos(e, 'peso_amostra', 'Peso da amostra (kg)');
  final n = _pos(e, 'n_amostrado', 'Nº de camarões amostrados');
  final g = pesoKg * 1000 / n;
  return ResultadoCalculo([
    ItemResultado('Peso médio', '${_fmt(g, 1)} g', destaque: true),
    ItemResultado('Peso da amostra', '${_fmt(pesoKg)} kg'),
    ItemResultado('Camarões amostrados', _fmt(n)),
  ]);
}

ResultadoCalculo _ganhoPeso(Map<String, double> e) {
  final inicial = _req(e, 'peso_inicial', 'Peso inicial (g)');
  final atual = _req(e, 'peso_atual', 'Peso atual (g)');
  final ganho = atual - inicial;
  return ResultadoCalculo([
    ItemResultado('Ganho de peso', '${_fmt(ganho, 1)} g', destaque: true),
    ItemResultado('Peso inicial', '${_fmt(inicial, 1)} g'),
    ItemResultado('Peso atual', '${_fmt(atual, 1)} g'),
  ]);
}

ResultadoCalculo _crescSemanal(Map<String, double> e) {
  final anterior = _req(e, 'peso_anterior', 'Peso anterior (g)');
  final atual = _req(e, 'peso_atual', 'Peso atual (g)');
  final semanas = _pos(e, 'semanas', 'Intervalo (semanas)');
  final gPorSem = (atual - anterior) / semanas;
  return ResultadoCalculo([
    ItemResultado('Crescimento semanal', '${_fmt(gPorSem, 2)} g/semana', destaque: true),
    ItemResultado('Peso anterior', '${_fmt(anterior, 1)} g'),
    ItemResultado('Peso atual', '${_fmt(atual, 1)} g'),
    ItemResultado('Intervalo', '${_fmt(semanas)} semanas'),
  ]);
}

ResultadoCalculo _tce(Map<String, double> e) {
  final inicial = _pos(e, 'peso_inicial', 'Peso inicial (g)');
  final finalP = _pos(e, 'peso_final', 'Peso final (g)');
  final dias = _pos(e, 'dias', 'Nº de dias');
  final tce = (math.log(finalP) - math.log(inicial)) / dias * 100;
  return ResultadoCalculo([
    ItemResultado('TCE', '${_fmt(tce, 2)} %/dia', destaque: true),
    ItemResultado('Peso inicial', '${_fmt(inicial, 1)} g'),
    ItemResultado('Peso final', '${_fmt(finalP, 1)} g'),
    ItemResultado('Período', '${_fmt(dias)} dias'),
  ]);
}

ResultadoCalculo _biomassa(Map<String, double> e) {
  final densidade = _pos(e, 'densidade', 'Densidade (cam/m²)');
  final area = _pos(e, 'area', 'Área do viveiro (ha)');
  final pesoMedio = _pos(e, 'peso_medio', 'Peso médio (g)');
  final kg = calcularBiomassa(densidade, area, pesoMedio);
  return ResultadoCalculo([
    ItemResultado('Biomassa', '${_fmt(kg)} kg', destaque: true),
    ItemResultado('Densidade', '${_fmt(densidade, 1)} cam/m²'),
    ItemResultado('Área do viveiro', '${_fmt(area)} ha'),
    ItemResultado('Peso médio', '${_fmt(pesoMedio, 1)} g'),
  ]);
}

ResultadoCalculo _arracoamento(Map<String, double> e) {
  final biomassa = _req(e, 'biomassa', 'Biomassa (kg)');
  final taxa = _req(e, 'taxa', 'Taxa de alimentação (%)');
  final racaoKgDia = racaoPorDia(biomassa, taxa);
  return ResultadoCalculo([
    ItemResultado('Ração por dia', '${_fmt(racaoKgDia)} kg/dia', destaque: true),
    ItemResultado('Biomassa', '${_fmt(biomassa)} kg'),
    ItemResultado('Taxa de alimentação', '${_fmt(taxa, 1)}%'),
  ]);
}

ResultadoCalculo _caa(Map<String, double> e) {
  final racao = _pos(e, 'racao', 'Ração consumida (kg)');
  final ganho = _pos(e, 'ganho_biomassa', 'Ganho de biomassa (kg)');
  final caa = _arred(racao / ganho, 2);
  return ResultadoCalculo([
    ItemResultado('CAA', _fmt(caa), destaque: true),
    ItemResultado('Ração consumida', '${_fmt(racao)} kg'),
    ItemResultado('Ganho de biomassa', '${_fmt(ganho)} kg'),
  ]);
}

ResultadoCalculo _produtividade(Map<String, double> e) {
  final biomassa = _req(e, 'biomassa', 'Biomassa final (kg)');
  final area = _pos(e, 'area', 'Área do viveiro (ha)');
  final kgHa = biomassa / area;
  return ResultadoCalculo([
    ItemResultado('Produtividade', '${_fmt(kgHa)} kg/ha', destaque: true),
    ItemResultado('Biomassa final', '${_fmt(biomassa)} kg'),
    ItemResultado('Área do viveiro', '${_fmt(area)} ha'),
  ]);
}

ResultadoCalculo _renovacaoAgua(Map<String, double> e) {
  final total = _pos(e, 'volume_total', 'Volume do viveiro (m³)');
  final renovado = _req(e, 'volume_renovado', 'Volume renovado (m³)');
  final pct = renovado / total * 100;
  return ResultadoCalculo([
    ItemResultado('Renovação de água', '${_fmt(pct, 1)}%', destaque: true),
    ItemResultado('Volume do viveiro', '${_fmt(total)} m³'),
    ItemResultado('Volume renovado', '${_fmt(renovado)} m³'),
  ]);
}

// ---------------------------------------------------------------------------
// Registro das 12 calculadoras
// ---------------------------------------------------------------------------

final List<DefinicaoCalculadora> _todas = [
  DefinicaoCalculadora(
    tipo: TipoCalculadora.densidade,
    titulo: 'Densidade de Estocagem',
    descricao: 'Quantos camarões existem por m² do viveiro.',
    icone: '📊',
    campos: [
      CampoEntrada(id: 'n_camaroes', rotulo: 'Nº de camarões'),
      CampoEntrada(id: 'area', rotulo: 'Área do viveiro', unidade: 'ha', chaveViveiro: 'area'),
    ],
    calcular: _densidade,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.povoamento,
    titulo: 'Povoamento',
    descricao: 'Quantos camarões colocar no viveiro para a densidade desejada.',
    icone: '🐟',
    campos: [
      CampoEntrada(id: 'area', rotulo: 'Área do viveiro', unidade: 'ha', chaveViveiro: 'area'),
      CampoEntrada(id: 'densidade', rotulo: 'Densidade desejada', unidade: 'cam/m²', chaveViveiro: 'densidade'),
    ],
    calcular: _povoamento,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.sobrevivencia,
    titulo: 'Sobrevivência',
    descricao: 'Percentual de camarões que permaneceram vivos.',
    icone: '🦐',
    campos: [
      CampoEntrada(id: 'n_inicial', rotulo: 'Nº inicial de camarões'),
      CampoEntrada(id: 'n_atual', rotulo: 'Nº atual/final de camarões'),
    ],
    calcular: _sobrevivencia,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.pesoMedio,
    titulo: 'Peso Médio',
    descricao: 'Peso médio de cada camarão a partir de uma amostra.',
    icone: '⚖️',
    campos: [
      CampoEntrada(id: 'peso_amostra', rotulo: 'Peso da amostra', unidade: 'kg'),
      CampoEntrada(id: 'n_amostrado', rotulo: 'Nº de camarões amostrados'),
    ],
    calcular: _pesoMedio,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.ganhoPeso,
    titulo: 'Ganho de Peso',
    descricao: 'Quanto o camarão ganhou de peso.',
    icone: '📈',
    campos: [
      CampoEntrada(id: 'peso_inicial', rotulo: 'Peso inicial', unidade: 'g'),
      CampoEntrada(id: 'peso_atual', rotulo: 'Peso atual', unidade: 'g'),
    ],
    calcular: _ganhoPeso,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.crescimentoSemanal,
    titulo: 'Crescimento Semanal',
    descricao: 'Quanto o camarão cresce por semana.',
    icone: '⏫',
    campos: [
      CampoEntrada(id: 'peso_anterior', rotulo: 'Peso anterior', unidade: 'g'),
      CampoEntrada(id: 'peso_atual', rotulo: 'Peso atual', unidade: 'g'),
      CampoEntrada(id: 'semanas', rotulo: 'Intervalo', unidade: 'semanas'),
    ],
    calcular: _crescSemanal,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.tce,
    titulo: 'TCE',
    descricao: 'Taxa de crescimento específico em % ao dia.',
    icone: '🔬',
    campos: [
      CampoEntrada(id: 'peso_inicial', rotulo: 'Peso inicial', unidade: 'g'),
      CampoEntrada(id: 'peso_final', rotulo: 'Peso final', unidade: 'g'),
      CampoEntrada(id: 'dias', rotulo: 'Nº de dias'),
    ],
    calcular: _tce,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.biomassa,
    titulo: 'Biomassa',
    descricao: 'Peso total estimado dos camarões no viveiro.',
    icone: '🪣',
    campos: [
      CampoEntrada(id: 'densidade', rotulo: 'Densidade', unidade: 'cam/m²', chaveViveiro: 'densidade'),
      CampoEntrada(id: 'area', rotulo: 'Área do viveiro', unidade: 'ha', chaveViveiro: 'area'),
      CampoEntrada(id: 'peso_medio', rotulo: 'Peso médio', unidade: 'g', chaveViveiro: 'peso_medio'),
    ],
    calcular: _biomassa,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.arracoamento,
    titulo: 'Arraçoamento',
    descricao: 'Quantidade de ração a fornecer por dia.',
    icone: '🍽️',
    campos: [
      CampoEntrada(id: 'biomassa', rotulo: 'Biomassa', unidade: 'kg'),
      CampoEntrada(id: 'taxa', rotulo: 'Taxa de alimentação', unidade: '%', valorPadrao: 5),
      CampoEntrada(
          id: 'marca',
          rotulo: 'Marca da ração',
          chaveViveiro: 'marca',
          texto: true),
    ],
    calcular: _arracoamento,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.caa,
    titulo: 'Conversão Alimentar (CAA)',
    descricao: 'Eficiência da ração utilizada.',
    icone: '🔄',
    campos: [
      CampoEntrada(id: 'racao', rotulo: 'Ração consumida', unidade: 'kg'),
      CampoEntrada(id: 'ganho_biomassa', rotulo: 'Ganho de biomassa', unidade: 'kg'),
    ],
    calcular: _caa,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.produtividade,
    titulo: 'Produtividade',
    descricao: 'Produção obtida por área.',
    icone: '🏭',
    campos: [
      CampoEntrada(id: 'biomassa', rotulo: 'Biomassa final', unidade: 'kg'),
      CampoEntrada(id: 'area', rotulo: 'Área do viveiro', unidade: 'ha', chaveViveiro: 'area'),
    ],
    calcular: _produtividade,
  ),
  DefinicaoCalculadora(
    tipo: TipoCalculadora.renovacaoAgua,
    titulo: 'Renovação de Água',
    descricao: 'Percentual de água renovada.',
    icone: '💧',
    campos: [
      CampoEntrada(id: 'volume_total', rotulo: 'Volume do viveiro', unidade: 'm³'),
      CampoEntrada(id: 'volume_renovado', rotulo: 'Volume renovado', unidade: 'm³'),
    ],
    calcular: _renovacaoAgua,
  ),
];

final Map<TipoCalculadora, DefinicaoCalculadora> calculadorasPorTipo =
    {for (final d in _todas) d.tipo: d};

List<DefinicaoCalculadora> get todasCalculadoras => _todas;
