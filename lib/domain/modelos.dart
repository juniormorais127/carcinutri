/// Tipos das 12 calculadoras disponíveis.
enum TipoCalculadora {
  densidade,
  povoamento,
  sobrevivencia,
  pesoMedio,
  ganhoPeso,
  crescimentoSemanal,
  tce,
  biomassa,
  arracoamento,
  caa,
  produtividade,
  renovacaoAgua,
}

/// Um viveiro cadastrado pelo produtor.
class Viveiro {
  final String id;
  final String nome;

  /// Área do viveiro em hectares.
  final double areaHa;

  /// Densidade padrão (cam/m²), opcional — pré-preenche calculadoras.
  final double? densidadePadrao;

  /// Marca da ração usada, opcional — pré-preenche o arraçoamento.
  final String? marcaRacao;

  /// Data de povoamento, opcional — base para calcular a idade do camarão e
  /// comparar a biometria com o crescimento esperado na projeção.
  final DateTime? dataPovoamento;
  final DateTime criadoEm;

  Viveiro({
    required this.id,
    required this.nome,
    required this.areaHa,
    this.densidadePadrao,
    this.marcaRacao,
    this.dataPovoamento,
    required this.criadoEm,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'nome': nome,
        'areaHa': areaHa,
        'densidadePadrao': densidadePadrao,
        'marcaRacao': marcaRacao,
        'dataPovoamento': dataPovoamento?.toIso8601String(),
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Viveiro.fromJson(Map<String, Object?> json) => Viveiro(
        id: json['id']! as String,
        nome: json['nome']! as String,
        areaHa: (json['areaHa']! as num).toDouble(),
        densidadePadrao: (json['densidadePadrao'] as num?)?.toDouble(),
        marcaRacao: json['marcaRacao'] as String?,
        dataPovoamento: json['dataPovoamento'] == null
            ? null
            : DateTime.parse(json['dataPovoamento']! as String),
        criadoEm: DateTime.parse(json['criadoEm']! as String),
      );

  Viveiro copiarCom({
    String? nome,
    double? areaHa,
    double? densidadePadrao,
    String? marcaRacao,
    DateTime? dataPovoamento,
  }) =>
      Viveiro(
        id: id,
        nome: nome ?? this.nome,
        areaHa: areaHa ?? this.areaHa,
        densidadePadrao: densidadePadrao,
        marcaRacao: marcaRacao,
        dataPovoamento: dataPovoamento,
        criadoEm: criadoEm,
      );
}

/// Um cálculo realizado, vinculado (opcionalmente) a um viveiro.
class Calculo {
  final String id;
  final String? viveiroId;
  final TipoCalculadora tipo;

  /// Entradas na ordem dos campos da definição.
  final Map<String, double> entradas;

  /// Itens de resultado (rótulo → valor) exibidos ao salvar.
  final Map<String, String> resultado;
  final DateTime criadoEm;

  Calculo({
    required this.id,
    this.viveiroId,
    required this.tipo,
    required this.entradas,
    required this.resultado,
    required this.criadoEm,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'viveiroId': viveiroId,
        'tipo': tipo.name,
        'entradas': entradas,
        'resultado': resultado,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Calculo.fromJson(Map<String, Object?> json) => Calculo(
        id: json['id']! as String,
        viveiroId: json['viveiroId'] as String?,
        tipo: TipoCalculadora.values.byName(json['tipo']! as String),
        entradas: (json['entradas']! as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        resultado: (json['resultado']! as Map).map(
          (k, v) => MapEntry(k as String, v as String),
        ),
        criadoEm: DateTime.parse(json['criadoEm']! as String),
      );
}

/// Uma biometria (amostragem de peso) registrada em um viveiro.
///
/// O peso médio é derivado de uma amostra: peso total da amostra (kg) dividido
/// pelo nº de camarões amostrados, convertido para gramas.
class Biometria {
  final String id;
  final String viveiroId;
  final DateTime data;
  final double pesoAmostraKg;
  final int nAmostrado;

  /// Peso médio em gramas = pesoAmostraKg × 1000 / nAmostrado.
  late final double pesoMedio = pesoAmostraKg * 1000 / nAmostrado;

  Biometria({
    required this.id,
    required this.viveiroId,
    required this.data,
    required this.pesoAmostraKg,
    required this.nAmostrado,
  }) {
    if (nAmostrado <= 0) {
      throw ArgumentError.value(nAmostrado, 'nAmostrado',
          'Deve ser maior que zero.');
    }
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'viveiroId': viveiroId,
        'data': data.toIso8601String(),
        'pesoAmostraKg': pesoAmostraKg,
        'nAmostrado': nAmostrado,
        'pesoMedio': pesoMedio,
      };

  factory Biometria.fromJson(Map<String, Object?> json) => Biometria(
        id: json['id']! as String,
        viveiroId: json['viveiroId']! as String,
        data: DateTime.parse(json['data']! as String),
        pesoAmostraKg: (json['pesoAmostraKg']! as num).toDouble(),
        nAmostrado: (json['nAmostrado']! as num).toInt(),
      );
}

/// Qualidade de água medida na mesma visita semanal da biometria (boas práticas
/// de manejo). Todos os parâmetros são opcionais — avalia-se os que foram
/// informados contra as faixas recomendadas (ABCC).
class QualidadeAgua {
  final String id;
  final String viveiroId;
  final DateTime data;
  final double? od;
  final double? ph;
  final double? temperatura;
  final double? amonia;
  final double? nitrito;
  final double? alcalinidade;

  QualidadeAgua({
    required this.id,
    required this.viveiroId,
    required this.data,
    this.od,
    this.ph,
    this.temperatura,
    this.amonia,
    this.nitrito,
    this.alcalinidade,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'viveiroId': viveiroId,
        'data': data.toIso8601String(),
        'od': od,
        'ph': ph,
        'temperatura': temperatura,
        'amonia': amonia,
        'nitrito': nitrito,
        'alcalinidade': alcalinidade,
      };

  factory QualidadeAgua.fromJson(Map<String, Object?> json) => QualidadeAgua(
        id: json['id']! as String,
        viveiroId: json['viveiroId']! as String,
        data: DateTime.parse(json['data']! as String),
        od: (json['od'] as num?)?.toDouble(),
        ph: (json['ph'] as num?)?.toDouble(),
        temperatura: (json['temperatura'] as num?)?.toDouble(),
        amonia: (json['amonia'] as num?)?.toDouble(),
        nitrito: (json['nitrito'] as num?)?.toDouble(),
        alcalinidade: (json['alcalinidade'] as num?)?.toDouble(),
      );
}
