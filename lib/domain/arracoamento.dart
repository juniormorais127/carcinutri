/// Recomendação de arraçoamento por espécie (fonte FAO).
///
/// Para o peso médio atual do camarão, interpola a taxa de alimentação entre
/// os pontos de referência da tabela e divide a ração diária em tratos,
/// indicando também como usar a bandeja de alimentação.
///
/// Esta tabela é específica da **engorda** de *Litopenaeus vannamei*
/// (2,5–22 g). Para pesos abaixo de 2,5 g não há extrapolação (fase de
/// pós-larva/berçário); acima de 22 g a taxa é tratada como um teto
/// (o usuário pode definir uma taxa manual, que nunca é alterada).
library;

import 'calculadoras.dart' show CalculoInvalido, racaoPorDia;

/// Uma faixa de peso da tabela de arraçoamento de uma espécie.
class FaixaArracoamento {
  final double minPeso; // g
  final double maxPeso; // g

  /// Taxa de alimentação (%) nos extremos da faixa (base para interpolação).
  final double taxaInicial;
  final double taxaFinal;

  /// Frequência recomendada (nº de refeições por dia).
  final int tratosMin;
  final int tratosMax;

  /// Bandeja de alimentação: % da ração a colocar na bandeja e tempo de
  /// verificação (horas).
  final double bandejaPct;
  final double bandejaTempoH;

  const FaixaArracoamento({
    required this.minPeso,
    required this.maxPeso,
    required this.taxaInicial,
    required this.taxaFinal,
    required this.tratosMin,
    required this.tratosMax,
    required this.bandejaPct,
    required this.bandejaTempoH,
  });
}

/// Metadados de arraçoamento de uma espécie (config centralizada).
class EspecieArracoamento {
  final String nome;
  final String nomeCientifico;
  final String fase;
  final double densidadeRefMin; // PL/m²
  final double densidadeRefMax; // PL/m²
  final double fcrRefMin;
  final double fcrRefMax;
  final String fonte;
  final double pesoMin; // g — início da tabela (não extrapolar abaixo)
  final double pesoMax; // g — fim da tabela (acima disso = teto)
  final List<FaixaArracoamento> faixas;

  const EspecieArracoamento({
    required this.nome,
    required this.nomeCientifico,
    required this.fase,
    required this.densidadeRefMin,
    required this.densidadeRefMax,
    required this.fcrRefMin,
    required this.fcrRefMax,
    required this.fonte,
    required this.pesoMin,
    required this.pesoMax,
    required this.faixas,
  });
}

/// Tabela FAO de arraçoamento para *L. vannamei* — fase engorda.
///
/// Pontos de referência: 2,5 g→5,8% · 3,5 g→4,8% · 8,0 g→3,2% · 12,5 g→2,6% ·
/// 17,5 g→2,2% · 22 g→1,8% (taxa = % da biomassa por dia).
const EspecieArracoamento especieVannamei = EspecieArracoamento(
  nome: 'Camarão-branco-do-Pacífico',
  nomeCientifico: 'Litopenaeus vannamei',
  fase: 'engorda',
  densidadeRefMin: 80,
  densidadeRefMax: 120,
  fcrRefMin: 1.4,
  fcrRefMax: 1.6,
  fonte: 'FAO',
  pesoMin: 2.5,
  pesoMax: 22,
  faixas: [
    FaixaArracoamento(
      minPeso: 2.5,
      maxPeso: 3.5,
      taxaInicial: 5.8,
      taxaFinal: 4.8,
      tratosMin: 4,
      tratosMax: 4,
      bandejaPct: 0.6,
      bandejaTempoH: 2.3,
    ),
    FaixaArracoamento(
      minPeso: 3.5,
      maxPeso: 8.0,
      taxaInicial: 4.8,
      taxaFinal: 3.2,
      tratosMin: 4,
      tratosMax: 5,
      bandejaPct: 0.8,
      bandejaTempoH: 2.0,
    ),
    FaixaArracoamento(
      minPeso: 8.0,
      maxPeso: 12.5,
      taxaInicial: 3.2,
      taxaFinal: 2.6,
      tratosMin: 5,
      tratosMax: 5,
      bandejaPct: 1.0,
      bandejaTempoH: 1.45,
    ),
    FaixaArracoamento(
      minPeso: 12.5,
      maxPeso: 17.5,
      taxaInicial: 2.6,
      taxaFinal: 2.2,
      tratosMin: 5,
      tratosMax: 5,
      bandejaPct: 1.2,
      bandejaTempoH: 1.0,
    ),
    FaixaArracoamento(
      minPeso: 17.5,
      maxPeso: 22.0,
      taxaInicial: 2.2,
      taxaFinal: 1.8,
      tratosMin: 5,
      tratosMax: 6,
      bandejaPct: 1.4,
      bandejaTempoH: 1.3,
    ),
  ],
);

/// Retorna a faixa de [especie] que contém [peso] (g), ou null se o peso
/// estiver fora da tabela (abaixo de [EspecieArracoamento.pesoMin] ou acima
/// de [pesoMax]).
FaixaArracoamento? faixaParaPeso(EspecieArracoamento especie, double peso) {
  for (final f in especie.faixas) {
    if (peso >= f.minPeso && peso <= f.maxPeso) return f;
  }
  return null;
}

/// Taxa de alimentação (%) em [peso] por interpolação linear entre os
/// extremos de [faixa].
double interpolateFeedingRate(FaixaArracoamento faixa, double peso) {
  final span = faixa.maxPeso - faixa.minPeso;
  if (span <= 0) return faixa.taxaFinal;
  final t = (peso - faixa.minPeso) / span;
  return faixa.taxaInicial + (faixa.taxaFinal - faixa.taxaInicial) * t;
}

/// Camarões vivos a partir dos povoados e da sobrevivência (%).
///
/// Lança [CalculoInvalido] se os povoados forem ≤ 0 ou a sobrevivência
/// estiver fora de 0–100%.
int calcularCamaroesVivos(int povoados, double sobrevivenciaPct) {
  if (povoados <= 0) {
    throw CalculoInvalido('O nº de camarões povoados precisa ser maior que zero.');
  }
  if (sobrevivenciaPct.isNaN ||
      sobrevivenciaPct < 0 ||
      sobrevivenciaPct > 100) {
    throw CalculoInvalido('A sobrevivência precisa estar entre 0 e 100%.');
  }
  return (povoados * sobrevivenciaPct / 100).round();
}

/// Biomassa (kg) a partir do nº de camarões vivos e do peso médio (g):
/// nº vivos × peso (g) ÷ 1000.
double calcularBiomassaViva(int nVivos, double pesoMedioG) {
  return nVivos * pesoMedioG / 1000;
}

/// Ração por trato (kg) = ração diária (kg) ÷ nº de tratos.
double calcularRacaoPorTrato(double racaoDiariaKg, int nTratos) {
  return racaoDiariaKg / nTratos;
}

/// Recomendação de arraçoamento calculada.
class RecomendacaoArracoamento {
  final int nVivos;
  final double biomassaKg;
  final double pesoMedio;

  /// Taxa de alimentação (%) efetivamente usada; null quando não há taxa
  /// definida (peso abaixo da tabela).
  final double? taxaPct;

  /// Texto curto exibido da taxa (ex.: "3,21% da biomassa/dia").
  final String taxaDescricao;

  /// Descrição técnica da faixa usada na interpolação.
  final String faixaTecnica;

  final int tratosMin;
  final int tratosMax;
  final int nTratos;

  final double racaoDiariaKg;
  final double racaoPorTratoKg;

  /// Bandeja de alimentação (pode ser null abaixo da tabela).
  final double? bandejaPct;
  final double? bandejaTempoH;

  /// 'ok' | 'abaixo' (peso < início da tabela) | 'acima' (peso > fim).
  final String status;

  /// Aviso técnico a exibir (fora da faixa / limite superior / taxa manual).
  final String? aviso;

  /// True quando a taxa veio do usuário (modo manual) e não foi alterada.
  final bool taxaManual;

  RecomendacaoArracoamento({
    required this.nVivos,
    required this.biomassaKg,
    required this.pesoMedio,
    required this.taxaPct,
    required this.taxaDescricao,
    required this.faixaTecnica,
    required this.tratosMin,
    required this.tratosMax,
    required this.nTratos,
    required this.racaoDiariaKg,
    required this.racaoPorTratoKg,
    required this.bandejaPct,
    required this.bandejaTempoH,
    required this.status,
    this.aviso,
    required this.taxaManual,
  });
}

double _reqNum(double v, String rotulo) {
  if (v.isNaN || v.isInfinite) {
    throw CalculoInvalido('Informe um valor válido em "$rotulo".');
  }
  if (v < 0) {
    throw CalculoInvalido('"$rotulo" não pode ser negativo.');
  }
  return v;
}

double _posNum(double v, String rotulo) {
  final x = _reqNum(v, rotulo);
  if (x == 0) {
    throw CalculoInvalido('"$rotulo" precisa ser maior que zero.');
  }
  return x;
}

int _reqInt(int v, String rotulo) {
  if (v <= 0) {
    throw CalculoInvalido('"$rotulo" precisa ser maior que zero.');
  }
  return v;
}

String _fmt(double v) {
  final s = v.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Calcula a recomendação de arraçoamento para a [especie] no [pesoMedio]
/// atual, com [nVivos] camarões vivos.
///
/// - [nTratos]: frequência desejada, validada dentro da faixa da espécie
///   (padrão = mínimo recomendado).
/// - [taxaManual]: modo manual — a taxa informada pelo usuário é usada como
///   está (nunca alterada). Só faz sentido para pesos acima da tabela ou se o
///   produtor quiser sobrepor a recomendação.
///
/// Lança [CalculoInvalido] para entradas inválidas.
RecomendacaoArracoamento recomendarArracoamento({
  required EspecieArracoamento especie,
  required double pesoMedio,
  required int nVivos,
  int? nTratos,
  double? taxaManual,
}) {
  _posNum(pesoMedio, 'peso médio');
  _reqInt(nVivos, 'nº de camarões vivos');
  if (taxaManual != null) _reqNum(taxaManual, 'taxa');

  final biomassa = calcularBiomassaViva(nVivos, pesoMedio);
  final faixa = faixaParaPeso(especie, pesoMedio);

  // Peso abaixo da tabela FAO: não extrapolar.
  if (faixa == null && pesoMedio < especie.pesoMin) {
    return RecomendacaoArracoamento(
      nVivos: nVivos,
      biomassaKg: biomassa,
      pesoMedio: pesoMedio,
      taxaPct: null,
      taxaDescricao: '—',
      faixaTecnica: 'peso abaixo da tabela',
      tratosMin: 0,
      tratosMax: 0,
      nTratos: 0,
      racaoDiariaKg: 0,
      racaoPorTratoKg: 0,
      bandejaPct: null,
      bandejaTempoH: null,
      status: 'abaixo',
      aviso:
          'O peso médio (${_fmt(pesoMedio)} g) está abaixo do início da '
              'tabela FAO (${_fmt(especie.pesoMin)} g). Nesta fase '
              '(pós-larva/berçário) a taxa não deve ser extrapolada — use o '
              'manejo específico para essa fase.',
      taxaManual: false,
    );
  }

  // Peso acima da tabela: usar taxa manual ou o teto da tabela.
  if (faixa == null) {
    final manual = taxaManual;
    final usarTeto = manual == null;
    final taxa = manual ?? especie.faixas.last.taxaFinal;
    final tratos = _escolherTratos(especie.faixas.last, nTratos);
    final racaoDia = racaoPorDia(biomassa, taxa);
    return RecomendacaoArracoamento(
      nVivos: nVivos,
      biomassaKg: biomassa,
      pesoMedio: pesoMedio,
      taxaPct: taxa,
      taxaDescricao: usarTeto
          ? 'abaixo de ${_fmt(especie.faixas.last.taxaFinal)}% da biomassa/dia'
          : '${_fmt(taxa)}% (taxa definida pelo usuário)',
      faixaTecnica: 'peso acima da tabela (teto ${_fmt(especie.faixas.last.taxaFinal)}%)',
      tratosMin: especie.faixas.last.tratosMin,
      tratosMax: especie.faixas.last.tratosMax,
      nTratos: tratos,
      racaoDiariaKg: racaoDia,
      racaoPorTratoKg: calcularRacaoPorTrato(racaoDia, tratos),
      bandejaPct: especie.faixas.last.bandejaPct,
      bandejaTempoH: especie.faixas.last.bandejaTempoH,
      status: 'acima',
      aviso: usarTeto
          ? 'O peso médio (${_fmt(pesoMedio)} g) está acima da tabela FAO '
              '(${_fmt(especie.pesoMax)} g). Foi usada a taxa limite de '
              '${_fmt(especie.faixas.last.taxaFinal)}% como teto — reduza '
              'abaixo disso e monitore o consumo na bandeja.'
          : 'Peso acima da tabela FAO (${_fmt(especie.pesoMax)} g). Usando a '
              'taxa manual de ${_fmt(taxa)}% da biomassa/dia.',
      taxaManual: !usarTeto,
    );
  }

  // Dentro da tabela: interpola a taxa e usa a faixa da espécie.
  final taxa = interpolateFeedingRate(faixa, pesoMedio);
  final tratos = _escolherTratos(faixa, nTratos);
  final manual = taxaManual;
  final taxaUsada = manual ?? taxa;
  return RecomendacaoArracoamento(
    nVivos: nVivos,
    biomassaKg: biomassa,
    pesoMedio: pesoMedio,
    taxaPct: taxaUsada,
    taxaDescricao: manual == null
        ? '${_fmt(taxa)}% da biomassa/dia'
        : '${_fmt(manual)}% (taxa definida pelo usuário)',
    faixaTecnica: 'interpolação entre ${_fmt(faixa.minPeso)} g '
        '(${_fmt(faixa.taxaInicial)}%) e ${_fmt(faixa.maxPeso)} g '
        '(${_fmt(faixa.taxaFinal)}%)',
    tratosMin: faixa.tratosMin,
    tratosMax: faixa.tratosMax,
    nTratos: tratos,
    racaoDiariaKg: racaoPorDia(biomassa, taxaUsada),
    racaoPorTratoKg: calcularRacaoPorTrato(racaoPorDia(biomassa, taxaUsada), tratos),
    bandejaPct: faixa.bandejaPct,
    bandejaTempoH: faixa.bandejaTempoH,
    status: 'ok',
    aviso: manual == null
        ? null
        : 'Usando a taxa manual de ${_fmt(manual)}% da biomassa/dia '
            '(a recomendação FAO para ${_fmt(pesoMedio)} g é '
            '${_fmt(taxa)}%). A taxa manual não foi alterada.',
    taxaManual: manual != null,
  );
}

int _escolherTratos(FaixaArracoamento faixa, int? nTratos) {
  if (nTratos == null) return faixa.tratosMin;
  if (nTratos < faixa.tratosMin || nTratos > faixa.tratosMax) {
    throw CalculoInvalido(
        'Nº de tratos precisa estar entre ${faixa.tratosMin} e '
        '${faixa.tratosMax}.');
  }
  return nTratos;
}
