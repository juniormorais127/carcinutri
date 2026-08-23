import 'dart:math' as math;

import 'calculadoras.dart';
import 'crescimento.dart';
import 'modelos.dart';
import 'projecao.dart';

/// Resumo de um viveiro para o painel, derivado apenas dos dados locais.
class ResumoViveiro {
  final Viveiro viveiro;

  /// Peso médio (g) da biometria mais recente; `null` se não houver.
  final double? pesoMedioG;

  /// Idade do ciclo em dias (desde o povoamento); `null` se não houver data.
  final int? idadeDias;

  /// Biomassa estimada (kg) = densidade × área × peso médio; `null` se faltar
  /// densidade ou biometria.
  final double? biomassaKg;

  /// Ração do dia (kg/dia) = biomassa × taxa de alimentação FAO pelo peso.
  final double? racaoDiaKg;

  /// FCA esperado do ciclo (ração total / biomassa final) pela curva de
  /// referência; `null` se faltar densidade.
  final double? fcaProjetado;

  /// Alertas de qualidade de água (última medição fora da faixa ABCC).
  final List<String> alertasAgua;

  const ResumoViveiro({
    required this.viveiro,
    required this.pesoMedioG,
    required this.idadeDias,
    required this.biomassaKg,
    required this.racaoDiaKg,
    required this.fcaProjetado,
    required this.alertasAgua,
  });
}

/// Totais de todos os viveiros para o topo do painel.
class ResumoGeral {
  final int nViveiros;
  final double areaTotalHa;
  final double? biomassaTotalKg;
  final double? racaoTotalDiaKg;
  final int nAlertas;
  const ResumoGeral({
    required this.nViveiros,
    required this.areaTotalHa,
    required this.biomassaTotalKg,
    required this.racaoTotalDiaKg,
    required this.nAlertas,
  });
}

/// Prevê a despesca a partir do ritmo real de crescimento das biometrias.
class PrevisaoDespesca {
  final double pesoAtualG;
  final double ganhoDiarioMedio;
  final int diasParaAlvo;
  final DateTime dataDespesca;

  /// Nº estimado de camarões; `null` se o viveiro não tem densidade.
  final int? nCamaroes;

  /// Produção estimada (kg); `null` se faltar densidade.
  final double? producaoKg;

  /// Receita estimada (R$); `null` se faltar densidade.
  final double? receitaEstimada;

  const PrevisaoDespesca({
    required this.pesoAtualG,
    required this.ganhoDiarioMedio,
    required this.diasParaAlvo,
    required this.dataDespesca,
    required this.nCamaroes,
    required this.producaoKg,
    required this.receitaEstimada,
  });
}

/// Faixas recomendadas de qualidade de água (ABCC, *L. vannamei*).
/// Cada entrada é [rotulo, id do campo, min, max]; `null` num extremo = sem
/// limite naquele lado.
const List<(String, String, double?, double?)> _faixasAgua = [
  ('OD', 'od', 4, null),
  ('pH', 'ph', 7.5, 8.5),
  ('Temperatura', 'temperatura', 28, 32),
  ('Amônia', 'amonia', null, 0.1),
  ('Nitrito', 'nitrito', null, 1.0),
  ('Alcalinidade', 'alcalinidade', 100, null),
];

/// Avalia uma medição de qualidade de água contra as faixas ABCC e devolve as
/// mensagens de alerta (vazio = tudo dentro da faixa).
List<String> alertasQualidadeAgua(QualidadeAgua q) {
  final alertas = <String>[];
  double? get(String campo) => switch (campo) {
        'od' => q.od,
        'ph' => q.ph,
        'temperatura' => q.temperatura,
        'amonia' => q.amonia,
        'nitrito' => q.nitrito,
        'alcalinidade' => q.alcalinidade,
        _ => null,
      };
  for (final (rotulo, campo, min, max) in _faixasAgua) {
    final v = get(campo);
    if (v == null) continue;
    if (min != null && v < min) {
      alertas.add('$rotulo baixo (${_fmt(v)}) — mínimo ${_fmt(min)}');
    } else if (max != null && v > max) {
      alertas.add('$rotulo alto (${_fmt(v)}) — máximo ${_fmt(max)}');
    }
  }
  return alertas;
}

/// Última biometria (mais recente) de uma lista; `null` se vazia.
Biometria? ultimaBiometria(List<Biometria> biometrias) {
  if (biometrias.isEmpty) return null;
  Biometria? maisRecente;
  for (final b in biometrias) {
    if (maisRecente == null || b.data.isAfter(maisRecente.data)) {
      maisRecente = b;
    }
  }
  return maisRecente;
}

/// Última medição de qualidade de água; `null` se vazia.
QualidadeAgua? ultimaQualidadeAgua(List<QualidadeAgua> qas) {
  if (qas.isEmpty) return null;
  QualidadeAgua? maisRecente;
  for (final q in qas) {
    if (maisRecente == null || q.data.isAfter(maisRecente.data)) {
      maisRecente = q;
    }
  }
  return maisRecente;
}

/// Monta o resumo de um viveiro para o painel.
ResumoViveiro resumirViveiro(
  Viveiro v,
  List<Biometria> biometrias,
  List<QualidadeAgua> qas, {
  DateTime? agora,
  double sobrevivenciaPct = 80,
}) {
  final hoje = agora ?? DateTime.now();
  final bio = ultimaBiometria(biometrias);
  final dens = v.densidadePadrao;

  final double? pesoMedioG = bio?.pesoMedio;
  final int? idadeDias = v.dataPovoamento == null
      ? null
      : math.max(0, hoje.difference(v.dataPovoamento!).inDays);

  final double? biomassaKg = (dens != null && pesoMedioG != null)
      ? calcularBiomassa(dens, v.areaHa, pesoMedioG)
      : null;

  final double? racaoDiaKg =
      (biomassaKg != null && pesoMedioG != null)
          ? racaoPorDia(biomassaKg, taxaAlimentacao(pesoMedioG))
          : null;

  final double? fcaProjetado = (dens != null)
      ? projetarCiclo(
          areaHa: v.areaHa,
          densidade: dens,
          sobrevivenciaPct: sobrevivenciaPct,
        ).fca
      : null;

  final qa = ultimaQualidadeAgua(qas);
  final alertas = qa == null ? const <String>[] : alertasQualidadeAgua(qa);

  return ResumoViveiro(
    viveiro: v,
    pesoMedioG: pesoMedioG,
    idadeDias: idadeDias,
    biomassaKg: biomassaKg,
    racaoDiaKg: racaoDiaKg,
    fcaProjetado: fcaProjetado,
    alertasAgua: alertas,
  );
}

/// Soma os resumos em totais para o topo do painel.
ResumoGeral resumirGeral(List<ResumoViveiro> resumos) {
  var area = 0.0;
  double? biomassa;
  double? racao;
  var nAlertas = 0;
  for (final r in resumos) {
    area += r.viveiro.areaHa;
    if (r.biomassaKg != null) {
      biomassa = (biomassa ?? 0) + r.biomassaKg!;
    }
    if (r.racaoDiaKg != null) {
      racao = (racao ?? 0) + r.racaoDiaKg!;
    }
    nAlertas += r.alertasAgua.length;
  }
  return ResumoGeral(
    nViveiros: resumos.length,
    areaTotalHa: area,
    biomassaTotalKg: biomassa,
    racaoTotalDiaKg: racao,
    nAlertas: nAlertas,
  );
}

/// Prevê a data de despesca e a produção/receita usando o ritmo de crescimento
/// real das biometrias. Retorna `null` se não houver biometrias suficientes
/// para estimar um ganho diário (menos de 2 amostras) ou se o peso alvo já foi
/// atingido.
PrevisaoDespesca? preverDespesca(
  Viveiro v,
  List<Biometria> biometrias, {
  required double pesoAlvoG,
  required double precoPorKg,
  double sobrevivenciaPct = 80,
  DateTime? agora,
}) {
  if (pesoAlvoG <= 0) return null;
  final resumo = resumirCrescimento(biometrias);
  if (resumo == null || resumo.ganhoDiarioMedio <= 0) return null;
  final pesoAtual = resumo.pesoFinal;
  if (pesoAtual >= pesoAlvoG) return null;

  final diasParaAlvo = ((pesoAlvoG - pesoAtual) / resumo.ganhoDiarioMedio)
      .ceil();
  final ultima = ultimaBiometria(biometrias);
  final dataDespesca =
      (ultima?.data ?? agora ?? DateTime.now()).add(Duration(days: diasParaAlvo));

  final dens = v.densidadePadrao;
  final int? nCamaroes = dens == null
      ? null
      : (dens * v.areaHa * 10000 * sobrevivenciaPct / 100).round();
  final double? producaoKg =
      nCamaroes == null ? null : nCamaroes * pesoAlvoG / 1000;
  final double? receita =
      producaoKg == null ? null : producaoKg * precoPorKg;

  return PrevisaoDespesca(
    pesoAtualG: pesoAtual,
    ganhoDiarioMedio: resumo.ganhoDiarioMedio,
    diasParaAlvo: diasParaAlvo,
    dataDespesca: dataDespesca,
    nCamaroes: nCamaroes,
    producaoKg: producaoKg,
    receitaEstimada: receita,
  );
}

String _fmt(double v) {
  final s = v.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}
