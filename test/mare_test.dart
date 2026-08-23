import 'package:carcini_calc/domain/mare.dart';
import 'package:flutter_test/flutter_test.dart';

final _dia = DateTime(2026, 1, 10);
const _preamar = Duration(hours: 6); // 06:00

EventoMare? _eventoEm(ResumoMare r, DateTime t) {
  for (final e in r.eventos) {
    if (e.tempo == t) return e;
  }
  return null;
}

void main() {
  group('calcularMare · semidiurna', () {
    final r = calcularMare(
      data: _dia,
      amplitudeM: 2.0,
      nivelMedioM: 0,
      tipo: TipoMare.semidiurna,
      horaPreamar: _preamar,
    );

    test('preamar no horário informado tem altura +amplitude/2', () {
      final e = _eventoEm(r, _dia.add(const Duration(hours: 6)));
      expect(e, isNotNull);
      expect(e!.tipo, TipoEventoMare.preamar);
      expect(e.alturaM, closeTo(1.0, 1e-6));
    });

    test('baixa-mar ~período/2 depois tem altura −amplitude/2', () {
      // 12h25m/2 = 6h12m30s depois da preamar das 06:00 → 12:12:30.
      final t = _dia.add(const Duration(hours: 12, minutes: 12, seconds: 30));
      final e = _eventoEm(r, t);
      expect(e, isNotNull);
      expect(e!.tipo, TipoEventoMare.baixaMar);
      expect(e.alturaM, closeTo(-1.0, 1e-6));
    });

    test('dia gera 2 preamares e 1 baixa-mar dentro de hoje', () {
      final hoje = r.eventosDeHoje;
      final fim = _dia.add(const Duration(hours: 24));
      for (final e in hoje) {
        expect(e.tempo.isBefore(fim), isTrue);
        expect(e.tempo.isBefore(_dia), isFalse);
      }
      expect(hoje.where((e) => e.tipo == TipoEventoMare.preamar).length, 2);
      expect(hoje.where((e) => e.tipo == TipoEventoMare.baixaMar).length, 1);
    });

    test('curva cobre o dia e bate na preamar', () {
      expect(r.curva, isNotEmpty);
      expect(r.curva.first.tempo, _dia);
      AlturaPonto? ponto;
      for (final p in r.curva) {
        if (p.tempo == _dia.add(const Duration(hours: 6))) {
          ponto = p;
          break;
        }
      }
      expect(ponto, isNotNull);
      expect(ponto!.alturaM, closeTo(1.0, 1e-6));
    });
  });

  group('proximoEvento', () {
    final r = calcularMare(
      data: _dia,
      amplitudeM: 2.0,
      nivelMedioM: 0,
      tipo: TipoMare.semidiurna,
      horaPreamar: _preamar,
    );

    test('retorna o evento seguinte a um dado instante', () {
      final prox = r.proximoEvento(_dia.add(const Duration(hours: 12)));
      expect(prox, isNotNull);
      // Próximo após o meio-dia é a baixa-mar das 12:12:30.
      expect(prox!.tempo, _dia.add(const Duration(hours: 12, minutes: 12, seconds: 30)));
      expect(prox.tipo, TipoEventoMare.baixaMar);
    });

    test('retorna null quando não há evento dentro das 48h', () {
      final prox = r.proximoEvento(_dia.add(const Duration(hours: 48)));
      expect(prox, isNull);
    });
  });

  group('calcularMare · diurna', () {
    test('dia gera 1 preamar e 1 baixa-mar dentro de hoje', () {
      final r = calcularMare(
        data: _dia,
        amplitudeM: 2.0,
        nivelMedioM: 0,
        tipo: TipoMare.diurna,
        horaPreamar: _preamar,
      );
      final hoje = r.eventosDeHoje;
      expect(hoje.where((e) => e.tipo == TipoEventoMare.preamar).length, 1);
      expect(hoje.where((e) => e.tipo == TipoEventoMare.baixaMar).length, 1);
    });

    test('baixa-mar diurna ~12h25m depois da preamar', () {
      final r = calcularMare(
        data: _dia,
        amplitudeM: 2.0,
        nivelMedioM: 0,
        tipo: TipoMare.diurna,
        horaPreamar: _preamar,
      );
      // 24h50/2 = 12h25m depois das 06:00 → 18:25.
      final e = _eventoEm(r, _dia.add(const Duration(hours: 18, minutes: 25)));
      expect(e, isNotNull);
      expect(e!.tipo, TipoEventoMare.baixaMar);
      expect(e.alturaM, closeTo(-1.0, 1e-6));
    });
  });
}
