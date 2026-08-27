import 'dart:math';

/// Gera UUID v4 aleatório compatível com colunas UUID do PostgreSQL.
String gerarUuidV4() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

/// Modelos de domínio do marketplace de serviços (Produtor ↔ Técnico) e custódia.

class SolicitacaoServico {
  final String id;
  final String? produtorId;
  final String produtorNome;
  final String titulo;
  final String? descricao;
  final String? categoria;
  final String? cidade;
  final double valorEstimado;
  final String status; // 'aberto', 'aceito', 'cancelado'
  final DateTime criadoEm;
  final bool sincronizado;

  SolicitacaoServico({
    required this.id,
    this.produtorId,
    this.produtorNome = '',
    required this.titulo,
    this.descricao,
    this.categoria,
    this.cidade,
    required this.valorEstimado,
    this.status = 'aberto',
    required this.criadoEm,
    this.sincronizado = false,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'produtor_id': produtorId,
        'produtor_nome': produtorNome,
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria,
        'cidade': cidade,
        'valor_estimado': valorEstimado,
        'status': status,
        'criado_em': criadoEm.toIso8601String(),
        'sincronizado': sincronizado,
      };

  factory SolicitacaoServico.fromJson(Map<String, Object?> json) =>
      SolicitacaoServico(
        id: json['id'] as String,
        produtorId: json['produtor_id'] as String?,
        produtorNome: (json['produtor_nome'] as String?) ?? '',
        titulo: (json['titulo'] as String?) ?? '',
        descricao: json['descricao'] as String?,
        categoria: json['categoria'] as String?,
        cidade: json['cidade'] as String?,
        valorEstimado: (json['valor_estimado'] as num?)?.toDouble() ?? 0.0,
        status: (json['status'] as String?) ?? 'aberto',
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'] as String)
            : DateTime.now(),
        sincronizado: (json['sincronizado'] as bool?) ?? true,
      );

  SolicitacaoServico copiarCom({
    String? id,
    String? produtorId,
    String? produtorNome,
    String? titulo,
    String? descricao,
    String? categoria,
    String? cidade,
    double? valorEstimado,
    String? status,
    DateTime? criadoEm,
    bool? sincronizado,
  }) =>
      SolicitacaoServico(
        id: id ?? this.id,
        produtorId: produtorId ?? this.produtorId,
        produtorNome: produtorNome ?? this.produtorNome,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        categoria: categoria ?? this.categoria,
        cidade: cidade ?? this.cidade,
        valorEstimado: valorEstimado ?? this.valorEstimado,
        status: status ?? this.status,
        criadoEm: criadoEm ?? this.criadoEm,
        sincronizado: sincronizado ?? this.sincronizado,
      );

  SolicitacaoServico marcadoSincronizado() => copiarCom(sincronizado: true);
}

class PropostaServico {
  final String id;
  final String servicoId;
  final String tecnicoId;
  final String tecnicoNome;
  final double valor;
  final String? mensagem;
  final String status; // 'pendente', 'aceita', 'recusada', 'retirada'
  final DateTime criadoEm;

  PropostaServico({
    required this.id,
    required this.servicoId,
    required this.tecnicoId,
    required this.tecnicoNome,
    required this.valor,
    this.mensagem,
    required this.status,
    required this.criadoEm,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'servico_id': servicoId,
        'tecnico_id': tecnicoId,
        'tecnico_nome': tecnicoNome,
        'valor': valor,
        'mensagem': mensagem,
        'status': status,
        'criado_em': criadoEm.toIso8601String(),
      };

  factory PropostaServico.fromJson(Map<String, Object?> json) =>
      PropostaServico(
        id: json['id'] as String,
        servicoId: (json['servico_id'] as String?) ?? '',
        tecnicoId: (json['tecnico_id'] as String?) ?? '',
        tecnicoNome: (json['tecnico_nome'] as String?) ?? '',
        valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
        mensagem: json['mensagem'] as String?,
        status: (json['status'] as String?) ?? 'pendente',
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'] as String)
            : DateTime.now(),
      );
}

class ContratoServico {
  final String id;
  final String servicoId;
  final String servicoTitulo;
  final String produtorId;
  final String produtorNome;
  final String tecnicoId;
  final String tecnicoNome;
  final double valorAcordado;
  final String pagamento; // 'aguardando', 'pago', 'repassado', 'restituido'
  final String execucao; // 'aguardando_pagamento', 'em_andamento', 'aguardando_aprovacao', 'concluido', 'cancelado'
  final bool comunicacaoLiberada;
  final String? fotoVisita;
  final String? fotoSolucao;
  final String? descricaoSolucao;
  final DateTime criadoEm;

  ContratoServico({
    required this.id,
    required this.servicoId,
    required this.servicoTitulo,
    required this.produtorId,
    required this.produtorNome,
    required this.tecnicoId,
    required this.tecnicoNome,
    required this.valorAcordado,
    required this.pagamento,
    required this.execucao,
    required this.comunicacaoLiberada,
    this.fotoVisita,
    this.fotoSolucao,
    this.descricaoSolucao,
    required this.criadoEm,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'servico_id': servicoId,
        'servico_titulo': servicoTitulo,
        'produtor_id': produtorId,
        'produtor_nome': produtorNome,
        'tecnico_id': tecnicoId,
        'tecnico_nome': tecnicoNome,
        'valor_acordado': valorAcordado,
        'pagamento': pagamento,
        'execucao': execucao,
        'comunicacao_liberada': comunicacaoLiberada,
        'foto_visita': fotoVisita,
        'foto_solucao': fotoSolucao,
        'descricao_solucao': descricaoSolucao,
        'criado_em': criadoEm.toIso8601String(),
      };

  factory ContratoServico.fromJson(Map<String, Object?> json) => ContratoServico(
        id: json['id'] as String,
        servicoId: (json['servico_id'] as String?) ?? '',
        servicoTitulo: (json['servico_titulo'] as String?) ?? '',
        produtorId: (json['produtor_id'] as String?) ?? '',
        produtorNome: (json['produtor_nome'] as String?) ?? '',
        tecnicoId: (json['tecnico_id'] as String?) ?? '',
        tecnicoNome: (json['tecnico_nome'] as String?) ?? '',
        valorAcordado: (json['valor_acordado'] as num?)?.toDouble() ?? 0.0,
        pagamento: (json['pagamento'] as String?) ?? 'aguardando',
        execucao: (json['execucao'] as String?) ?? 'aguardando_pagamento',
        comunicacaoLiberada: (json['comunicacao_liberada'] as bool?) ?? false,
        fotoVisita: json['foto_visita'] as String?,
        fotoSolucao: json['foto_solucao'] as String?,
        descricaoSolucao: json['descricao_solucao'] as String?,
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'] as String)
            : DateTime.now(),
      );
}

class MensagemServico {
  final String id;
  final String contratoId;
  final String remetenteId;
  final String remetenteNome;
  final String texto;
  final DateTime criadoEm;

  MensagemServico({
    required this.id,
    required this.contratoId,
    required this.remetenteId,
    required this.remetenteNome,
    required this.texto,
    required this.criadoEm,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'contrato_id': contratoId,
        'remetente_id': remetenteId,
        'remetente_nome': remetenteNome,
        'texto': texto,
        'criado_em': criadoEm.toIso8601String(),
      };

  factory MensagemServico.fromJson(Map<String, Object?> json) =>
      MensagemServico(
        id: json['id'] as String,
        contratoId: (json['contrato_id'] as String?) ?? '',
        remetenteId: (json['remetente_id'] as String?) ?? '',
        remetenteNome: (json['remetente_nome'] as String?) ?? '',
        texto: (json['texto'] as String?) ?? '',
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'] as String)
            : DateTime.now(),
      );
}
