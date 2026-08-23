import 'dart:math';

/// Modelo de maré offline: senoide simples (semidiurna ou diurna).
///
/// Altura no instante t (em relação ao nível médio):
///   h(t) = nívelMédio + (amplitude/2) * cos(2π · ((t − tPreamar) mod período) / período)
///
/// Preamar (maré alta) ocorre em t = tPreamar + k·período;
/// baixa-mar em t = tPreamar + período/2 + k·período.
enum TipoMare { semidiurna, diurna }

extension TipoMareInfo on TipoMare {
  Duration get periodo => switch (this) {
        TipoMare.semidiurna => const Duration(hours: 12, minutes: 25),
        TipoMare.diurna => const Duration(hours: 24, minutes: 50),
      };

  String get rotulo => switch (this) {
        TipoMare.semidiurna => 'Semidiurna (12h25m)',
        TipoMare.diurna => 'Diurna (24h50m)',
      };
}

enum TipoEventoMare { preamar, baixaMar }

extension TipoEventoInfo on TipoEventoMare {
  String get rotulo => switch (this) {
        TipoEventoMare.preamar => 'Preamar (maré alta)',
        TipoEventoMare.baixaMar => 'Baixa-mar (maré baixa)',
      };

  String get curto => switch (this) {
        TipoEventoMare.preamar => 'Preamar',
        TipoEventoMare.baixaMar => 'Baixa-mar',
      };

  bool get ehPreamar => this == TipoEventoMare.preamar;
}

class EventoMare {
  final DateTime tempo;
  final double alturaM;
  final TipoEventoMare tipo;
  const EventoMare({required this.tempo, required this.alturaM, required this.tipo});
}

class AlturaPonto {
  final DateTime tempo;
  final double alturaM;
  const AlturaPonto({required this.tempo, required this.alturaM});
}

class ResumoMare {
  final DateTime data;
  final double amplitudeM;
  final double nivelMedioM;
  final TipoMare tipo;

  /// Eventos de maré (preamar/baixa) ao longo de ~48h (hoje + amanhã), ordenados.
  final List<EventoMare> eventos;

  /// Curva de altura da maré ao longo do dia de [data], a cada intervalo.
  final List<AlturaPonto> curva;

  const ResumoMare({
    required this.data,
    required this.amplitudeM,
    required this.nivelMedioM,
    required this.tipo,
    required this.eventos,
    required this.curva,
  });

  /// Eventos que caem no dia de referência [data].
  List<EventoMare> get eventosDeHoje {
    final fimDoDia = data.add(const Duration(hours: 24));
    return eventos.where((e) => !e.tempo.isBefore(data) && e.tempo.isBefore(fimDoDia)).toList();
  }

  /// Próximo evento de maré após [agora]; `null` se não houver dentro das 48h.
  EventoMare? proximoEvento(DateTime agora) {
    for (final e in eventos) {
      if (e.tempo.isAfter(agora)) return e;
    }
    return null;
  }
}

/// Calcula a altura da maré no instante de duração [t] desde a meia-noite de [data].
double _alturaM(
  Duration t, {
  required Duration horaPreamar,
  required Duration periodo,
  required double nivelMedioM,
  required double amplitudeM,
}) {
  final periodoS = periodo.inSeconds;
  final phase = (t.inSeconds - horaPreamar.inSeconds) % periodoS; // Dart % → não-negativo
  final rad = 2 * pi * phase / periodoS;
  return nivelMedioM + (amplitudeM / 2) * cos(rad);
}

/// Gera o resumo de maré para o dia [data], cobrindo ~48h de eventos e a curva do dia.
ResumoMare calcularMare({
  required DateTime data,
  required double amplitudeM,
  required TipoMare tipo,
  required double nivelMedioM,
  required Duration horaPreamar,
  Duration intervalo = const Duration(minutes: 30),
}) {
  final inicio = DateTime(data.year, data.month, data.day);
  final periodo = tipo.periodo;
  final periodoS = periodo.inSeconds;
  final preamarS = horaPreamar.inSeconds;
  const janela = Duration(hours: 48);
  final janelaS = janela.inSeconds;

  // --- Eventos (preamares e baixa-mares) dentro da janela de 48h ---
  final eventos = <EventoMare>[];
  final limiteK = janelaS ~/ periodoS + 2;
  for (var k = -1; k <= limiteK; k++) {
    void tenta(int sec, TipoEventoMare tipoEv) {
      if (sec < 0 || sec >= janelaS) return;
      final tempo = inicio.add(Duration(seconds: sec));
      final altura = _alturaM(Duration(seconds: sec),
          horaPreamar: horaPreamar,
          periodo: periodo,
          nivelMedioM: nivelMedioM,
          amplitudeM: amplitudeM);
      eventos.add(EventoMare(tempo: tempo, alturaM: altura, tipo: tipoEv));
    }

    tenta(preamarS + k * periodoS, TipoEventoMare.preamar);
    tenta(preamarS + periodoS ~/ 2 + k * periodoS, TipoEventoMare.baixaMar);
  }
  eventos.sort((a, b) => a.tempo.compareTo(b.tempo));

  // --- Curva do dia (a cada intervalo) ---
  final curva = <AlturaPonto>[];
  final intervaloS = intervalo.inSeconds <= 0 ? 1800 : intervalo.inSeconds;
  for (var s = 0; s < 24 * 3600; s += intervaloS) {
    final t = Duration(seconds: s);
    curva.add(AlturaPonto(
      tempo: inicio.add(t),
      alturaM: _alturaM(t,
          horaPreamar: horaPreamar,
          periodo: periodo,
          nivelMedioM: nivelMedioM,
          amplitudeM: amplitudeM),
    ));
  }

  return ResumoMare(
    data: inicio,
    amplitudeM: amplitudeM,
    nivelMedioM: nivelMedioM,
    tipo: tipo,
    eventos: eventos,
    curva: curva,
  );
}
