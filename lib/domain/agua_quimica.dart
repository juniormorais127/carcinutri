import 'dart:math' as math;

import 'modelos.dart';

/// Classificação do risco de toxicidade da amônia não-ionizada (NH3).
enum NivelRiscoAmonia {
  seguro,
  atencao,
  critico,
}

/// Resultado da partição da amônia e avaliação de toxicidade.
class AvaliacaoAmoniaToxica {
  /// Amônia total informada (TAN em mg/L).
  final double amoniaTotalMgL;

  /// Temperatura da água (°C) usada no cálculo.
  final double temperaturaC;

  /// pH da água usado no cálculo.
  final double ph;

  /// Salinidade da água em ppt (opcional, default 15 ppt).
  final double salinidadePpt;

  /// Fração de amônia que se encontra na forma tóxica não-ionizada (0.0 a 1.0).
  final double fracaoNaoIonizada;

  /// Percentual de amônia tóxica (0.0% a 100.0%).
  final double percentualNaoIonizada;

  /// Concentração de amônia tóxica não-ionizada (NH3 em mg/L).
  final double nh3ToxicoMgL;

  /// Nível de risco para o camarão Litopenaeus vannamei.
  final NivelRiscoAmonia risco;

  /// Mensagem técnica orientativa para o produtor.
  final String orientacao;

  const AvaliacaoAmoniaToxica({
    required this.amoniaTotalMgL,
    required this.temperaturaC,
    required this.ph,
    required this.salinidadePpt,
    required this.fracaoNaoIonizada,
    required this.percentualNaoIonizada,
    required this.nh3ToxicoMgL,
    required this.risco,
    required this.orientacao,
  });
}

/// Calcula a fração e concentração de amônia tóxica não-ionizada (NH3)
/// a partir da Amônia Total (TAN), pH, Temperatura e Salinidade.
///
/// Base científica:
/// - Emerson et al. (1975) / Johansson & Wedborg (1980) / Boyd (2020).
/// - Equilíbrio NH4+ <-> NH3 + H+.
/// - pKa = 2729.92 / (T_K) + 0.09018 + 0.0016 * Salinidade.
///
/// Faixas de risco para Litopenaeus vannamei (ABCC / Lin & Chen, 2001):
/// - NH3 < 0.05 mg/L: Seguro / Ótimo.
/// - NH3 entre 0.05 e 0.10 mg/L: Atenção (estresse fisiológico e branquial).
/// - NH3 > 0.10 mg/L: Crítico (risco de letalidade aguda e redução drástica de imunidade).
AvaliacaoAmoniaToxica calcularAmoniaToxica({
  required double amoniaTotalMgL,
  required double ph,
  required double temperaturaC,
  double salinidadePpt = 15.0,
}) {
  if (amoniaTotalMgL < 0) {
    throw ArgumentError.value(amoniaTotalMgL, 'amoniaTotalMgL', 'Não pode ser negativa.');
  }
  if (ph < 0 || ph > 14) {
    throw ArgumentError.value(ph, 'ph', 'pH deve estar entre 0 e 14.');
  }
  if (temperaturaC < 0 || temperaturaC > 60) {
    throw ArgumentError.value(temperaturaC, 'temperaturaC', 'Temperatura fora da faixa biológica.');
  }

  // Temperatura em Kelvin
  final tk = temperaturaC + 273.15;

  // Constante de dissociação da amônia com correção de força iônica por salinidade
  final pKa = (2729.92 / tk) + 0.09018 + (0.0016 * math.max(0.0, salinidadePpt));

  // Fração de amônia não-ionizada (NH3)
  final exp = pKa - ph;
  final fracao = 1.0 / (math.pow(10, exp) + 1.0);
  final nh3Toxico = amoniaTotalMgL * fracao;
  final pctNaoIonizada = fracao * 100.0;

  final NivelRiscoAmonia risco;
  final String orientacao;

  if (nh3Toxico < 0.05) {
    risco = NivelRiscoAmonia.seguro;
    orientacao = 'Nível seguro de NH3 tóxico (< 0,05 mg/L). Manter rotina de alimentação e monitoramento.';
  } else if (nh3Toxico <= 0.10) {
    risco = NivelRiscoAmonia.atencao;
    orientacao = 'Atenção: NH3 tóxico elevado (0,05 a 0,10 mg/L). Reduzir arraçoamento em 20-30%, verificar oxigenação e evitar picos de pH vespertino.';
  } else {
    risco = NivelRiscoAmonia.critico;
    orientacao = 'CRÍTICO: NH3 tóxico perigoso (> 0,10 mg/L). Suspender ou cortar 50% da ração, ligar aeradores em capacidade máxima e planejar renovação de água se viável.';
  }

  return AvaliacaoAmoniaToxica(
    amoniaTotalMgL: amoniaTotalMgL,
    temperaturaC: temperaturaC,
    ph: ph,
    salinidadePpt: salinidadePpt,
    fracaoNaoIonizada: fracao,
    percentualNaoIonizada: pctNaoIonizada,
    nh3ToxicoMgL: nh3Toxico,
    risco: risco,
    orientacao: orientacao,
  );
}

/// Avalia a amônia tóxica a partir de uma medição de [QualidadeAgua],
/// se amônia, pH e temperatura estiverem preenchidos.
AvaliacaoAmoniaToxica? avaliarAmoniaRegistro(QualidadeAgua q, {double salinidadePpt = 15.0}) {
  if (q.amonia == null || q.ph == null || q.temperatura == null) return null;
  return calcularAmoniaToxica(
    amoniaTotalMgL: q.amonia!,
    ph: q.ph!,
    temperaturaC: q.temperatura!,
    salinidadePpt: salinidadePpt,
  );
}

// ---------------------------------------------------------------------------
// Calagem e Correção de Solo/Água (Tabela 17 - Manual ABCC 2021)
// ---------------------------------------------------------------------------

/// Tipos de produtos de calagem e correção química.
enum TipoCorretivo {
  calcarioDolomitico, // Base (PRNT 100% / Fator 1.0)
  calcarioCalcico,    // PRNT 100% / Fator 1.0
  calHidratada,       // Ca(OH)2 - Fator 1.35
  calVirgem,          // CaO - Fator 1.78
  bicarbonatoSodio,   // NaHCO3 - Para elevar alcalinidade da água durante o ciclo
}

extension TipoCorretivoInfo on TipoCorretivo {
  String get nome => switch (this) {
        TipoCorretivo.calcarioDolomitico => 'Calcário Dolomítico (CaCO3 + MgCO3)',
        TipoCorretivo.calcarioCalcico => 'Calcário Agrícola / Cálcico (CaCO3)',
        TipoCorretivo.calHidratada => 'Cal Hidratada / Apagada [Ca(OH)2]',
        TipoCorretivo.calVirgem => 'Cal Virgem / Queimada [CaO]',
        TipoCorretivo.bicarbonatoSodio => 'Bicarbonato de Sódio (NaHCO3)',
      };

  double get fatorEquivalencia => switch (this) {
        TipoCorretivo.calcarioDolomitico => 1.0,
        TipoCorretivo.calcarioCalcico => 1.0,
        TipoCorretivo.calHidratada => 1.35,
        TipoCorretivo.calVirgem => 1.78,
        TipoCorretivo.bicarbonatoSodio => 1.20,
      };
}

/// Recomendação de calagem de preparação ou manutenção do viveiro.
class RecomendacaoCalagem {
  final double phSolo;
  final double areaHa;
  final TipoCorretivo corretivo;
  final double doseBaseKgHa;
  final double doseAjustadaKgHa;
  final double quantidadeTotalKg;
  final String indicacao;

  const RecomendacaoCalagem({
    required this.phSolo,
    required this.areaHa,
    required this.corretivo,
    required this.doseBaseKgHa,
    required this.doseAjustadaKgHa,
    required this.quantidadeTotalKg,
    required this.indicacao,
  });
}

/// Tabela 17 do Manual ABCC 2021 — Calagem de correção por pH do solo.
/// Retorna a dose de calcário (kg/ha) para correção do fundo.
double doseCalcarioTabela17(double phSolo) {
  if (phSolo < 5.0) return 3500.0; // Faixa < 5.0 (3.000 a 4.000 kg/ha)
  if (phSolo <= 5.5) return 2500.0; // Faixa 5.0 a 5.5 (2.000 a 3.000 kg/ha)
  if (phSolo <= 6.0) return 1750.0; // Faixa 5.6 a 6.0 (1.500 a 2.000 kg/ha)
  if (phSolo <= 6.5) return 1250.0; // Faixa 6.1 a 6.5 (1.000 a 1.500 kg/ha)
  return 500.0; // Faixa > 6.5 (Manutenção de alcalinidade)
}

/// Calcula a recomendação de calagem para o viveiro segundo o Manual ABCC 2021.
RecomendacaoCalagem calcularCalagem({
  required double phSolo,
  required double areaHa,
  TipoCorretivo corretivo = TipoCorretivo.calcarioDolomitico,
}) {
  if (areaHa <= 0) {
    throw ArgumentError.value(areaHa, 'areaHa', 'Área do viveiro deve ser maior que zero.');
  }
  if (phSolo <= 0 || phSolo > 14) {
    throw ArgumentError.value(phSolo, 'phSolo', 'pH do solo fora da escala.');
  }

  final doseBase = doseCalcarioTabela17(phSolo);
  final doseAjustada = doseBase / corretivo.fatorEquivalencia;
  final totalKg = doseAjustada * areaHa;

  final String indicacao;
  if (phSolo < 5.0) {
    indicacao = 'Solo fortemente ácido. Aplicação essencial para liberar nutrientes e evitar fixação de fósforo.';
  } else if (phSolo <= 6.0) {
    indicacao = 'Solo moderadamente ácido. Calagem recomendada para manter pH da água estável e alcalinidade > 80 mg/L.';
  } else if (phSolo <= 6.5) {
    indicacao = 'Solo levemente ácido. Calagem leve recomendada.';
  } else {
    indicacao = 'Solo em pH adequado. Dose de manutenção recomendada para tamponamento e reserva de cálcio/magnésio.';
  }

  return RecomendacaoCalagem(
    phSolo: phSolo,
    areaHa: areaHa,
    corretivo: corretivo,
    doseBaseKgHa: doseBase,
    doseAjustadaKgHa: doseAjustada,
    quantidadeTotalKg: totalKg,
    indicacao: indicacao,
  );
}

/// Calcula a quantidade de Bicarbonato de Sódio (NaHCO3) necessária para elevar
/// a alcalinidade total da água do viveiro até o nível alvo (ex.: 100-120 mg/L CaCO3).
///
/// Regra estequiométrica: 1 mg/L de alcalinidade (CaCO3) requer 1,68 g de NaHCO3 por m³ de água.
double calcularCorrecaoAlcalinidade({
  required double alcalinidadeAtualMgL,
  required double alcalinidadeAlvoMgL,
  required double areaHa,
  double profundidadeMediaM = 1.0,
}) {
  if (alcalinidadeAtualMgL >= alcalinidadeAlvoMgL) return 0.0;
  final deficitMgL = alcalinidadeAlvoMgL - alcalinidadeAtualMgL;
  final volumeM3 = areaHa * 10000.0 * profundidadeMediaM;
  // 1,68 g/m³ por mg/L = 0,00168 kg/m³
  return deficitMgL * 1.68 * volumeM3 / 1000.0; // Total em kg
}
