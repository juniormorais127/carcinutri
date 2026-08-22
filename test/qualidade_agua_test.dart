import 'package:carcini_calc/domain/modelos.dart';
import 'package:carcini_calc/domain/qualidade_agua.dart';
import 'package:flutter_test/flutter_test.dart';

QualidadeAgua _qa({double? od, double? ph, double? temperatura, double? amonia,
  double? nitrito, double? alcalinidade}) {
  return QualidadeAgua(
    id: '1',
    viveiroId: 'v1',
    data: DateTime(2026, 8, 22),
    od: od,
    ph: ph,
    temperatura: temperatura,
    amonia: amonia,
    nitrito: nitrito,
    alcalinidade: alcalinidade,
  );
}

void main() {
  group('Avaliação por faixas (ABCC)', () {
    test('OD: ≥4 OK, 3,7–4 atenção, <3,7 crítico', () {
      expect(_status(_qa(od: 5), 'od'), StatusQualidade.ok);
      expect(_status(_qa(od: 3.9), 'od'), StatusQualidade.atencao);
      expect(_status(_qa(od: 2), 'od'), StatusQualidade.critico);
    });

    test('pH: 7–8,5 OK, faixa limítrofe atenção, fora crítico', () {
      expect(_status(_qa(ph: 7.5), 'ph'), StatusQualidade.ok);
      expect(_status(_qa(ph: 6.8), 'ph'), StatusQualidade.atencao);
      expect(_status(_qa(ph: 8.8), 'ph'), StatusQualidade.atencao);
      expect(_status(_qa(ph: 5), 'ph'), StatusQualidade.critico);
      expect(_status(_qa(ph: 10), 'ph'), StatusQualidade.critico);
    });

    test('Amônia: <0,5 OK, 0,5–2 atenção, >2 crítico', () {
      expect(_status(_qa(amonia: 0.3), 'amonia'), StatusQualidade.ok);
      expect(_status(_qa(amonia: 1), 'amonia'), StatusQualidade.atencao);
      expect(_status(_qa(amonia: 2.5), 'amonia'), StatusQualidade.critico);
    });

    test('Nitrito: <0,2 OK, 0,2–0,5 atenção, >0,5 crítico', () {
      expect(_status(_qa(nitrito: 0.1), 'nitrito'), StatusQualidade.ok);
      expect(_status(_qa(nitrito: 0.3), 'nitrito'), StatusQualidade.atencao);
      expect(_status(_qa(nitrito: 0.8), 'nitrito'), StatusQualidade.critico);
    });

    test('Temperatura: 26–32 OK, limítrofe atenção, fora crítico', () {
      expect(_status(_qa(temperatura: 28), 'temperatura'), StatusQualidade.ok);
      expect(
          _status(_qa(temperatura: 25), 'temperatura'),
          StatusQualidade.atencao);
      expect(
          _status(_qa(temperatura: 35), 'temperatura'),
          StatusQualidade.critico);
    });

    test('Alcalinidade: 60–180 OK, 40–60 atenção, <40 crítico', () {
      expect(
          _status(_qa(alcalinidade: 100), 'alcalinidade'), StatusQualidade.ok);
      expect(
          _status(_qa(alcalinidade: 50), 'alcalinidade'),
          StatusQualidade.atencao);
      expect(
          _status(_qa(alcalinidade: 30), 'alcalinidade'),
          StatusQualidade.critico);
    });
  });

  group('Status geral', () {
    test('pior status vence: crítico domina atenção/OK', () {
      final av = avaliarQualidadeAgua(_qa(od: 5, amonia: 2.5, ph: 7));
      expect(av.statusGeral, StatusQualidade.critico);
    });

    test('atenção vence quando só há atenção e OK', () {
      final av = avaliarQualidadeAgua(_qa(od: 5, amonia: 1));
      expect(av.statusGeral, StatusQualidade.atencao);
    });

    test('tudo OK → status geral OK', () {
      final av = avaliarQualidadeAgua(_qa(od: 5, ph: 7.5, amonia: 0.3));
      expect(av.statusGeral, StatusQualidade.ok);
    });
  });

  test('parâmetros não informados não entram na avaliação', () {
    final av = avaliarQualidadeAgua(_qa(od: 5));
    expect(av.parametros.length, 1);
    expect(av.parametros.first.parametro, 'od');
  });

  test('QualidadeAgua serializa e desserializa mantendo valores nulos', () {
    final q = _qa(od: 5, ph: 7.5, temperatura: null);
    final c = QualidadeAgua.fromJson(Map<String, Object?>.from(q.toJson()));
    expect(c.od, 5);
    expect(c.ph, 7.5);
    expect(c.temperatura, isNull);
    expect(c.viveiroId, 'v1');
  });
}

StatusQualidade _status(QualidadeAgua q, String parametro) {
  final av = avaliarQualidadeAgua(q);
  return av.parametros.firstWhere((p) => p.parametro == parametro).status;
}
