import 'modelos.dart';

/// Status de um parâmetro de qualidade de água frente às faixas recomendadas.
enum StatusQualidade { ok, atencao, critico }

/// Avaliação de um único parâmetro informado.
class AvaliacaoParametro {
  final String parametro; // id ('od', 'ph', ...)
  final String rotulo;
  final String unidade;
  final double valor;
  final StatusQualidade status;

  /// Descrição das faixas recomendadas, exibida como referência.
  final String faixa;
  AvaliacaoParametro({
    required this.parametro,
    required this.rotulo,
    required this.unidade,
    required this.valor,
    required this.status,
    required this.faixa,
  });
}

/// Resultado completo da avaliação da qualidade de água.
class AvaliacaoQualidade {
  final List<AvaliacaoParametro> parametros;
  final StatusQualidade statusGeral;
  AvaliacaoQualidade(this.parametros, this.statusGeral);
}

String rotuloStatus(StatusQualidade s) {
  switch (s) {
    case StatusQualidade.ok:
      return 'OK';
    case StatusQualidade.atencao:
      return 'Atenção';
    case StatusQualidade.critico:
      return 'Crítico';
  }
}

// ---------------------------------------------------------------------------
// Faixas (ABCC / boas práticas): cada parâmetro vira OK, Atenção ou Crítico.
// ---------------------------------------------------------------------------

StatusQualidade _statusOd(double v) {
  if (v >= 4) return StatusQualidade.ok;
  if (v >= 3.7) return StatusQualidade.atencao;
  return StatusQualidade.critico;
}

StatusQualidade _statusPh(double v) {
  if (v < 6.5 || v > 9.5) return StatusQualidade.critico;
  if (v < 7 || v > 8.5) return StatusQualidade.atencao;
  return StatusQualidade.ok;
}

StatusQualidade _statusTemp(double v) {
  if (v < 24 || v > 34) return StatusQualidade.critico;
  if (v < 26 || v > 32) return StatusQualidade.atencao;
  return StatusQualidade.ok;
}

StatusQualidade _statusAmonia(double v) {
  if (v > 2) return StatusQualidade.critico;
  if (v >= 0.5) return StatusQualidade.atencao;
  return StatusQualidade.ok;
}

StatusQualidade _statusNitrito(double v) {
  if (v > 0.5) return StatusQualidade.critico;
  if (v >= 0.2) return StatusQualidade.atencao;
  return StatusQualidade.ok;
}

StatusQualidade _statusAlcalinidade(double v) {
  if (v < 40) return StatusQualidade.critico;
  if (v < 60 || v > 180) return StatusQualidade.atencao;
  return StatusQualidade.ok;
}

int _peso(StatusQualidade s) {
  switch (s) {
    case StatusQualidade.ok:
      return 0;
    case StatusQualidade.atencao:
      return 1;
    case StatusQualidade.critico:
      return 2;
  }
}

/// Avalia os parâmetros de qualidade de água informados.
///
/// Parâmetros não informados são ignorados. O [AvaliacaoQualidade.statusGeral]
/// é o pior status entre os parâmetros preenchidos.
AvaliacaoQualidade avaliarQualidadeAgua(QualidadeAgua q) {
  final lista = <AvaliacaoParametro>[];

  void add(
    String parametro,
    String rotulo,
    String unidade,
    double? valor,
    StatusQualidade Function(double) fn,
    String faixa,
  ) {
    if (valor == null) return;
    lista.add(AvaliacaoParametro(
      parametro: parametro,
      rotulo: rotulo,
      unidade: unidade,
      valor: valor,
      status: fn(valor),
      faixa: faixa,
    ));
  }

  add('od', 'Oxigênio dissolvido', 'mg/L', q.od, _statusOd,
      '≥ 4 mg/L · atenção 3,7–4 · crítico < 3,7');
  add('ph', 'pH', '', q.ph, _statusPh,
      '7–8,5 · atenção 6,5–7 e 8,5–9,5 · crítico <6,5 ou >9,5');
  add('temperatura', 'Temperatura', '°C', q.temperatura, _statusTemp,
      '26–32 °C · atenção 24–26 e 32–34 · crítico <24 ou >34');
  add('amonia', 'Amônia', 'mg/L', q.amonia, _statusAmonia,
      '< 0,5 mg/L · atenção 0,5–2 · crítico > 2');
  add('nitrito', 'Nitrito', 'mg/L', q.nitrito, _statusNitrito,
      '< 0,2 mg/L · atenção 0,2–0,5 · crítico > 0,5');
  add('alcalinidade', 'Alcalinidade', 'mg/L', q.alcalinidade,
      _statusAlcalinidade, '60–180 mg/L · atenção 40–60 e >180 · crítico <40');

  var geral = StatusQualidade.ok;
  for (final p in lista) {
    if (_peso(p.status) > _peso(geral)) geral = p.status;
  }
  return AvaliacaoQualidade(lista, geral);
}
