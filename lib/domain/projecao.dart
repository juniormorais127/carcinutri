/// Projeção de arraçoamento do ciclo + crescimento esperado.
///
/// Modela o crescimento do camarão por uma curva de referência (atinge o peso
/// alvo aos 70 dias, default 9,5 g) e, com a biomassa projetada e as taxas de
/// arraçoamento FAO (L. vannamei), estima a ração diária e o consumo total do
/// ciclo.
library;

import 'arracoamento.dart';

/// Um dia da projeção do ciclo.
class ProjecaoDia {
  final int dia;
  final double pesoMedio; // g
  final double taxaPct; // arraçoamento (% biomassa/dia)
  final double biomassaKg;
  final double racaoKgDia;
  final double racaoAcumuladaKg;
  ProjecaoDia({
    required this.dia,
    required this.pesoMedio,
    required this.taxaPct,
    required this.biomassaKg,
    required this.racaoKgDia,
    required this.racaoAcumuladaKg,
  });
}

/// Resumo da projeção de um ciclo completo.
class ProjecaoCiclo {
  final List<ProjecaoDia> dias;
  final int nCamaroes;
  final double pesoFinal; // g
  final double racaoTotalKg;
  final double racaoMediaDiaKg;
  final double fca;
  ProjecaoCiclo({
    required this.dias,
    required this.nCamaroes,
    required this.pesoFinal,
    required this.racaoTotalKg,
    required this.racaoMediaDiaKg,
    required this.fca,
  });
}

/// Resultado da comparação de uma biometria com o esperado pela curva.
class ComparacaoCrescimento {
  final double esperado; // g
  final double real; // g
  final double difG;
  final double difPct;
  final String status; // 'abaixo' | 'esperado' | 'acima'
  ComparacaoCrescimento({
    required this.esperado,
    required this.real,
    required this.difG,
    required this.difPct,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// Curva de crescimento (fração do peso aos 70 dias, por dia — interpolação)
// ---------------------------------------------------------------------------

/// Fração do peso final atingida em cada dia de referência (semanal).
/// Perfil realista de crescimento de *vannamei*: acelerando até o meio do
/// ciclo e desacelerando ao fim.
const Map<int, double> _fracaoPorDia = {
  0: 0.0,
  7: 0.02,
  14: 0.06,
  21: 0.14,
  28: 0.24,
  35: 0.37,
  42: 0.53,
  49: 0.67,
  56: 0.81,
  63: 0.93,
  70: 1.0,
};

/// Fração do peso final no [dia] (interpolação linear entre os pontos).
double _fracao(int dia) {
  if (dia <= 0) return _fracaoPorDia[0]!;
  if (dia >= 70) return _fracaoPorDia[70]!;
  int anterior = 0;
  for (final d in _fracaoPorDia.keys) {
    if (d > dia) break;
    anterior = d;
  }
  final posterior = anterior + 7;
  final fa = _fracaoPorDia[anterior]!;
  final fp = _fracaoPorDia[posterior]!;
  final t = (dia - anterior) / (posterior - anterior);
  return fa + (fp - fa) * t;
}

/// Peso médio esperado (g) no [dia], escalado entre [pesoInicial] e [peso70]
/// ao longo de [diasTotal] dias. Estritamente crescente; no dia 0 = pesoInicial
/// e no último dia = peso70.
double pesoEsperado(int dia,
    {double pesoInicial = 0.05, double peso70 = 9.5, int diasTotal = 70}) {
  if (dia <= 0) return pesoInicial;
  if (dia >= diasTotal) return peso70;
  final fracao = _fracao((dia * 70 / diasTotal).round());
  return pesoInicial + (peso70 - pesoInicial) * fracao;
}

// ---------------------------------------------------------------------------
// Taxa de arraçoamento FAO (% biomassa/dia) por peso médio
// ---------------------------------------------------------------------------

/// Taxa de arraçoamento (%) pela tabela FAO de *L. vannamei*, com
/// interpolação linear entre os pontos (2,5 g→5,8% ... 22 g→1,8%).
///
/// - Peso abaixo de 2,5 g (fase inicial do ciclo): usa **5,8%** — o limite
///   inferior da tabela — como teto, sem extrapolar.
/// - Peso acima de 22 g: usa **1,8%** como teto.
double taxaAlimentacao(double pesoG) {
  final faixa = faixaParaPeso(especieVannamei, pesoG);
  if (faixa != null) return interpolateFeedingRate(faixa, pesoG);
  if (pesoG < especieVannamei.pesoMin) {
    return especieVannamei.faixas.first.taxaInicial; // 5,8%
  }
  return especieVannamei.faixas.last.taxaFinal; // 1,8%
}

// ---------------------------------------------------------------------------
// Projeção do ciclo
// ---------------------------------------------------------------------------

/// Projeta o arraçoamento diário de [diasTotal] dias.
///
/// [sobrevivenciaPct] reduz o nº de camarões (densidade × área × sobrevivência).
/// FCA = ração total do ciclo / biomassa final (kg).
ProjecaoCiclo projetarCiclo({
  required double areaHa,
  required double densidade,
  required double sobrevivenciaPct,
  double pesoInicial = 0.05,
  double peso70 = 9.5,
  int diasTotal = 70,
}) {
  final nCamaroes =
      (densidade * areaHa * 10000 * sobrevivenciaPct / 100).round();
  final dias = <ProjecaoDia>[];
  var acumulado = 0.0;

  for (var dia = 0; dia <= diasTotal; dia++) {
    final peso = pesoEsperado(dia,
        pesoInicial: pesoInicial, peso70: peso70, diasTotal: diasTotal);
    final biomassa = nCamaroes * peso / 1000;
    final racao = biomassa * taxaAlimentacao(peso) / 100;
    acumulado += racao;
    dias.add(ProjecaoDia(
      dia: dia,
      pesoMedio: peso,
      taxaPct: taxaAlimentacao(peso),
      biomassaKg: biomassa,
      racaoKgDia: racao,
      racaoAcumuladaKg: acumulado,
    ));
  }

  final racaoTotalKg = dias.fold<double>(0, (s, d) => s + d.racaoKgDia);
  final pesoFinal = dias.last.pesoMedio;
  final biomassaFinal = nCamaroes * pesoFinal / 1000;
  return ProjecaoCiclo(
    dias: dias,
    nCamaroes: nCamaroes,
    pesoFinal: pesoFinal,
    racaoTotalKg: racaoTotalKg,
    racaoMediaDiaKg: racaoTotalKg / diasTotal,
    fca: biomassaFinal > 0 ? racaoTotalKg / biomassaFinal : 0,
  );
}

// ---------------------------------------------------------------------------
// Comparação biometria × esperado
// ---------------------------------------------------------------------------

/// Compara o peso real da biometria com o esperado pela curva.
/// Dentro de ±10% → 'esperado'; acima → 'acima'; abaixo → 'abaixo'.
ComparacaoCrescimento compararComEsperado({
  required double pesoReal,
  required double pesoEsperado,
}) {
  final difG = pesoReal - pesoEsperado;
  final difPct = pesoEsperado > 0 ? difG / pesoEsperado * 100 : 0.0;
  final String status;
  if (difPct > 10) {
    status = 'acima';
  } else if (difPct < -10) {
    status = 'abaixo';
  } else {
    status = 'esperado';
  }
  return ComparacaoCrescimento(
    esperado: pesoEsperado,
    real: pesoReal,
    difG: difG,
    difPct: difPct,
    status: status,
  );
}
