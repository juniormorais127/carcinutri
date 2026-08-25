
import 'calculadoras.dart' show CalculoInvalido;

/// Cenário de povoamento inicial segundo a Tabela 19 do Manual ABCC 2021.
enum TipoPovoamentoInicial {
  /// Povoamento direto em viveiro de engorda em condições de temperatura quente (>= 28°C).
  diretoQuente,

  /// Povoamento direto em viveiro de engorda em condições de temperatura fria (< 26°C).
  diretoFrio,

  /// Povoamento indireto (passagem por berçário/pré-berçário) em temperatura quente.
  indiretoQuente,

  /// Povoamento indireto (passagem por berçário/pré-berçário) em temperatura fria.
  indiretoFrio,
}

extension TipoPovoamentoInicialInfo on TipoPovoamentoInicial {
  String get rotulo => switch (this) {
        TipoPovoamentoInicial.diretoQuente => 'Povoamento Direto — Clima Quente (>= 28°C)',
        TipoPovoamentoInicial.diretoFrio => 'Povoamento Direto — Clima Frio (< 26°C)',
        TipoPovoamentoInicial.indiretoQuente => 'Povoamento Indireto (Berçário) — Clima Quente',
        TipoPovoamentoInicial.indiretoFrio => 'Povoamento Indireto (Berçário) — Clima Frio',
      };
}

/// Registro diário da Tabela 19 da ABCC (kg de ração/dia por 1.000.000 de PLs20).
class LinhaTabela19ABCC {
  final int semana;
  final int dia;
  final double dirQ;
  final double dirF;
  final double indQ;
  final double indF;

  const LinhaTabela19ABCC({
    required this.semana,
    required this.dia,
    required this.dirQ,
    required this.dirF,
    required this.indQ,
    required this.indF,
  });

  double valorPara(TipoPovoamentoInicial tipo) => switch (tipo) {
        TipoPovoamentoInicial.diretoQuente => dirQ,
        TipoPovoamentoInicial.diretoFrio => dirF,
        TipoPovoamentoInicial.indiretoQuente => indQ,
        TipoPovoamentoInicial.indiretoFrio => indF,
      };
}

/// Tabela 19 Oficial do Manual ABCC 2021 — Alimentação Inicial (kg/dia por 1M PLs20).
const List<LinhaTabela19ABCC> tabela19ABCC = [
  // Semana 1
  LinhaTabela19ABCC(semana: 1, dia: 1, dirQ: 20, dirF: 20, indQ: 25, indF: 25),
  LinhaTabela19ABCC(semana: 1, dia: 2, dirQ: 22, dirF: 21, indQ: 27, indF: 26),
  LinhaTabela19ABCC(semana: 1, dia: 3, dirQ: 24, dirF: 22, indQ: 29, indF: 27),
  LinhaTabela19ABCC(semana: 1, dia: 4, dirQ: 25, dirF: 23, indQ: 30, indF: 28),
  LinhaTabela19ABCC(semana: 1, dia: 5, dirQ: 27, dirF: 24, indQ: 32, indF: 29),
  LinhaTabela19ABCC(semana: 1, dia: 6, dirQ: 29, dirF: 25, indQ: 34, indF: 30),
  LinhaTabela19ABCC(semana: 1, dia: 7, dirQ: 30, dirF: 26, indQ: 35, indF: 31),
  // Semana 2
  LinhaTabela19ABCC(semana: 2, dia: 8, dirQ: 30, dirF: 26, indQ: 35, indF: 31),
  LinhaTabela19ABCC(semana: 2, dia: 9, dirQ: 30, dirF: 26, indQ: 35, indF: 31),
  LinhaTabela19ABCC(semana: 2, dia: 10, dirQ: 30, dirF: 26, indQ: 35, indF: 31),
  LinhaTabela19ABCC(semana: 2, dia: 11, dirQ: 31, dirF: 27, indQ: 36, indF: 32),
  LinhaTabela19ABCC(semana: 2, dia: 12, dirQ: 31, dirF: 27, indQ: 36, indF: 32),
  LinhaTabela19ABCC(semana: 2, dia: 13, dirQ: 31, dirF: 27, indQ: 36, indF: 32),
  LinhaTabela19ABCC(semana: 2, dia: 14, dirQ: 32, dirF: 28, indQ: 37, indF: 33),
  // Semana 3
  LinhaTabela19ABCC(semana: 3, dia: 15, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  LinhaTabela19ABCC(semana: 3, dia: 16, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  LinhaTabela19ABCC(semana: 3, dia: 17, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  LinhaTabela19ABCC(semana: 3, dia: 18, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  LinhaTabela19ABCC(semana: 3, dia: 19, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  LinhaTabela19ABCC(semana: 3, dia: 20, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  LinhaTabela19ABCC(semana: 3, dia: 21, dirQ: 36, dirF: 30, indQ: 39, indF: 34),
  // Semana 4
  LinhaTabela19ABCC(semana: 4, dia: 22, dirQ: 52, dirF: 43, indQ: 56, indF: 48),
  LinhaTabela19ABCC(semana: 4, dia: 23, dirQ: 52, dirF: 43, indQ: 56, indF: 48),
  LinhaTabela19ABCC(semana: 4, dia: 24, dirQ: 52, dirF: 43, indQ: 56, indF: 48),
];

/// Resultado do cálculo de ração inicial para a fase de berçário / primeiros 24 dias.
class RecomendacaoRacaoInicial {
  final int dia;
  final int semana;
  final TipoPovoamentoInicial tipoPovoamento;
  final int nPls;
  final double taxaTabela19KgPorMilhao;
  final double racaoDiariaKg;
  final int tratosSugeridos;
  final double racaoPorTratoKg;
  final String orientacaoManejo;

  const RecomendacaoRacaoInicial({
    required this.dia,
    required this.semana,
    required this.tipoPovoamento,
    required this.nPls,
    required this.taxaTabela19KgPorMilhao,
    required this.racaoDiariaKg,
    required this.tratosSugeridos,
    required this.racaoPorTratoKg,
    required this.orientacaoManejo,
  });
}

/// Calcula a alimentação inicial (Dias 1 a 24) a partir da Tabela 19 do Manual ABCC.
RecomendacaoRacaoInicial calcularAlimentacaoInicial({
  required int dia,
  required int nPls,
  TipoPovoamentoInicial tipoPovoamento = TipoPovoamentoInicial.diretoQuente,
  int? nTratos,
}) {
  if (dia < 1 || dia > 24) {
    throw CalculoInvalido('A Tabela 19 da ABCC atende os dias 1 a 24 (fase pós-larva inicial).');
  }
  if (nPls <= 0) {
    throw CalculoInvalido('O número de pós-larvas (PLs) deve ser maior que zero.');
  }

  final linha = tabela19ABCC.firstWhere((l) => l.dia == dia);
  final taxaBase = linha.valorPara(tipoPovoamento);
  final racaoDia = taxaBase * (nPls / 1000000.0);

  final int tratosPadrao = linha.semana <= 2 ? 4 : 5;
  final int tratos = nTratos ?? tratosPadrao;
  if (tratos <= 0) {
    throw CalculoInvalido('Nº de tratos precisa ser maior que zero.');
  }

  final racaoTrato = racaoDia / tratos;

  final String orientacao;
  if (linha.semana == 1) {
    orientacao = 'Semana 1: Distribuição uniforme a lanço em toda a margem/área do viveiro. Rações microextrusadas (0,5–0,8 mm).';
  } else if (linha.semana == 2) {
    orientacao = 'Semana 2: Início da transição de granulometria (0,8–1,2 mm). Manter horários rigorosos de arraçoamento.';
  } else if (linha.semana == 3) {
    orientacao = 'Semana 3: Iniciar o uso de bandejas de alimentação (Tabela 18) para monitorar o apetite e sobras.';
  } else {
    orientacao = 'Semana 4: Transição para ração de engorda e controle integral via bandejas de alimentação.';
  }

  return RecomendacaoRacaoInicial(
    dia: dia,
    semana: linha.semana,
    tipoPovoamento: tipoPovoamento,
    nPls: nPls,
    taxaTabela19KgPorMilhao: taxaBase,
    racaoDiariaKg: racaoDia,
    tratosSugeridos: tratos,
    racaoPorTratoKg: racaoTrato,
    orientacaoManejo: orientacao,
  );
}

// ---------------------------------------------------------------------------
// Tabela 18 ABCC — Bandejas de Alimentação por Densidade
// ---------------------------------------------------------------------------

/// Linha da Tabela 18 da ABCC (número de bandejas por hectare).
class FaixaBandejasABCC {
  final double densidadeMax; // cam/m²
  final int bandejasPorHa;
  final String descricao;

  const FaixaBandejasABCC({
    required this.densidadeMax,
    required this.bandejasPorHa,
    required this.descricao,
  });
}

const List<FaixaBandejasABCC> tabela18Bandejas = [
  FaixaBandejasABCC(densidadeMax: 20, bandejasPorHa: 20, descricao: 'Até 20 cam/m²: 20 bandejas/ha'),
  FaixaBandejasABCC(densidadeMax: 30, bandejasPorHa: 25, descricao: '20 a 30 cam/m²: 25 bandejas/ha'),
  FaixaBandejasABCC(densidadeMax: 40, bandejasPorHa: 35, descricao: '30 a 40 cam/m²: 35 bandejas/ha'),
  FaixaBandejasABCC(densidadeMax: 50, bandejasPorHa: 45, descricao: '40 a 50 cam/m²: 45 bandejas/ha'),
  FaixaBandejasABCC(densidadeMax: 60, bandejasPorHa: 50, descricao: '50 a 60 cam/m²: 50 bandejas/ha'),
  FaixaBandejasABCC(densidadeMax: 80, bandejasPorHa: 60, descricao: '60 a 80 cam/m²: 60 bandejas/ha'),
];

/// Retorna o número de bandejas/ha recomendado pela Tabela 18 da ABCC para uma dada densidade.
int bandejasPorHaABCC(double densidadeCamM2) {
  for (final b in tabela18Bandejas) {
    if (densidadeCamM2 <= b.densidadeMax) return b.bandejasPorHa;
  }
  return 70; // Para densidades > 80 cam/m² (cultivo intensivo/superintensivo)
}

/// Calcula a quantidade total de bandejas recomendadas para um viveiro.
int calcularTotalBandejasViveiro({
  required double densidadeCamM2,
  required double areaHa,
}) {
  if (densidadeCamM2 <= 0 || areaHa <= 0) return 0;
  final porHa = bandejasPorHaABCC(densidadeCamM2);
  return (porHa * areaHa).round();
}

// ---------------------------------------------------------------------------
// Motor de Ajuste de Arraçoamento por Consumo de Bandejas (Feed Tray Engine)
// ---------------------------------------------------------------------------

/// Ação recomendada para o próximo trato a partir da leitura da bandeja.
enum AcaoAjusteTrato {
  aumentar,
  manter,
  reduzirLeve,
  reduzirModerada,
  suspenderOuCortar,
}

/// Avaliação do consumo das bandejas de alimentação e recomendação de ajuste do trato.
class AjusteConsumoBandeja {
  final double sobraPercentual;
  final double? oxigenioDissolvidoMgL;
  final AcaoAjusteTrato acao;
  final double fatorMultiplicador;
  final double racaoOriginalKg;
  final double racaoAjustadaKg;
  final String justificativa;

  const AjusteConsumoBandeja({
    required this.sobraPercentual,
    this.oxigenioDissolvidoMgL,
    required this.acao,
    required this.fatorMultiplicador,
    required this.racaoOriginalKg,
    required this.racaoAjustadaKg,
    required this.justificativa,
  });
}

/// Avalia o consumo de ração nas bandejas e calcula a dose corrigida para o próximo trato.
///
/// Regras zootécnicas consolidadas (ABCC / Boyd):
/// - Se OD < 3.5 mg/L: Suspender trato ou cortar em 50% (evita hipóxia e pico de amônia).
/// - Sobra 0% (Bandeja limpa no tempo limite ou antes): Aumentar em +5% a +10%.
/// - Sobra 1% a 5%: Consumo ideal -> Manter quantidade (fator 1.0).
/// - Sobra 6% a 15%: Sobra leve/moderada -> Reduzir em -10%.
/// - Sobra 16% a 25%: Sobra expressiva -> Reduzir em -25%.
/// - Sobra > 25%: Sobra excessiva -> Suspender próximo trato ou cortar em -50%.
AjusteConsumoBandeja calcularAjusteBandeja({
  required double sobraPercentual,
  required double racaoTratoKg,
  double? oxigenioDissolvidoMgL,
}) {
  if (sobraPercentual < 0 || sobraPercentual > 100) {
    throw ArgumentError.value(sobraPercentual, 'sobraPercentual', 'Sobra deve estar entre 0% e 100%.');
  }
  if (racaoTratoKg < 0) {
    throw ArgumentError.value(racaoTratoKg, 'racaoTratoKg', 'Ração do trato não pode ser negativa.');
  }

  // Regra crítica de Oxigênio Dissolvido
  if (oxigenioDissolvidoMgL != null && oxigenioDissolvidoMgL < 3.5) {
    return AjusteConsumoBandeja(
      sobraPercentual: sobraPercentual,
      oxigenioDissolvidoMgL: oxigenioDissolvidoMgL,
      acao: AcaoAjusteTrato.suspenderOuCortar,
      fatorMultiplicador: 0.5,
      racaoOriginalKg: racaoTratoKg,
      racaoAjustadaKg: racaoTratoKg * 0.5,
      justificativa: 'Oxigênio Crítico (< 3,5 mg/L). Reduzir trato em 50% para evitar anóxia por digestão e acúmulo de matéria orgânica.',
    );
  }

  if (sobraPercentual == 0.0) {
    return AjusteConsumoBandeja(
      sobraPercentual: sobraPercentual,
      oxigenioDissolvidoMgL: oxigenioDissolvidoMgL,
      acao: AcaoAjusteTrato.aumentar,
      fatorMultiplicador: 1.08,
      racaoOriginalKg: racaoTratoKg,
      racaoAjustadaKg: racaoTratoKg * 1.08,
      justificativa: 'Bandeja totalmente limpa. Aumentar o próximo trato em +8% para suprir a demanda de crescimento.',
    );
  } else if (sobraPercentual <= 5.0) {
    return AjusteConsumoBandeja(
      sobraPercentual: sobraPercentual,
      oxigenioDissolvidoMgL: oxigenioDissolvidoMgL,
      acao: AcaoAjusteTrato.manter,
      fatorMultiplicador: 1.0,
      racaoOriginalKg: racaoTratoKg,
      racaoAjustadaKg: racaoTratoKg,
      justificativa: 'Consumo ideal (sobra entre 1% e 5%). Manter a quantidade do trato.',
    );
  } else if (sobraPercentual <= 15.0) {
    return AjusteConsumoBandeja(
      sobraPercentual: sobraPercentual,
      oxigenioDissolvidoMgL: oxigenioDissolvidoMgL,
      acao: AcaoAjusteTrato.reduzirLeve,
      fatorMultiplicador: 0.90,
      racaoOriginalKg: racaoTratoKg,
      racaoAjustadaKg: racaoTratoKg * 0.90,
      justificativa: 'Sobra leve a moderada (${sobraPercentual.toStringAsFixed(1)}%). Reduzir próximo trato em 10%.',
    );
  } else if (sobraPercentual <= 25.0) {
    return AjusteConsumoBandeja(
      sobraPercentual: sobraPercentual,
      oxigenioDissolvidoMgL: oxigenioDissolvidoMgL,
      acao: AcaoAjusteTrato.reduzirModerada,
      fatorMultiplicador: 0.75,
      racaoOriginalKg: racaoTratoKg,
      racaoAjustadaKg: racaoTratoKg * 0.75,
      justificativa: 'Sobra expressiva (${sobraPercentual.toStringAsFixed(1)}%). Reduzir próximo trato em 25% e checar parâmetros de água.',
    );
  } else {
    return AjusteConsumoBandeja(
      sobraPercentual: sobraPercentual,
      oxigenioDissolvidoMgL: oxigenioDissolvidoMgL,
      acao: AcaoAjusteTrato.suspenderOuCortar,
      fatorMultiplicador: 0.50,
      racaoOriginalKg: racaoTratoKg,
      racaoAjustadaKg: racaoTratoKg * 0.50,
      justificativa: 'Sobra excessiva (> 25%). Cortar 50% do próximo trato para evitar deterioração do sedimento do viveiro.',
    );
  }
}
