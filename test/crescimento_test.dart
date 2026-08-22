import 'package:carcini_calc/domain/crescimento.dart';
import 'package:carcini_calc/domain/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

Biometria _bio(String id, DateTime data, double pesoAmostraKg, int n) =>
    Biometria(id: id, viveiroId: 'v1', data: data,
        pesoAmostraKg: pesoAmostraKg, nAmostrado: n);

void main() {
  group('biometriasCronologicas', () {
    test('ordena por data ascendente', () {
      final b1 = _bio('1', DateTime(2026, 1, 10), 0.05, 100);
      final b2 = _bio('2', DateTime(2026, 1, 3), 0.02, 100);
      final b3 = _bio('3', DateTime(2026, 1, 17), 0.09, 100);

      final ordenadas = biometriasCronologicas([b1, b3, b2]);
      expect(ordenadas.map((b) => b.id), ['2', '1', '3']);
    });

    test('retorna lista vazia quando entrada vazia', () {
      expect(biometriasCronologicas([]), isEmpty);
    });
  });

  group('resumirCrescimento', () {
    test('retorna null com lista vazia', () {
      expect(resumirCrescimento([]), isNull);
    });

    test('retorna null com apenas 1 amostra', () {
      final b = _bio('1', DateTime(2026, 1, 10), 0.05, 100); // 0,5 g
      expect(resumirCrescimento([b]), isNull);
    });

    test('calcula resumo com 2 amostras', () {
      // 0,5 g no dia 10 → 2,5 g no dia 24 (14 dias depois), ganho 2 g.
      final b1 = _bio('1', DateTime(2026, 1, 10), 0.05, 100);
      final b2 = _bio('2', DateTime(2026, 1, 24), 0.25, 100);

      final r = resumirCrescimento([b1, b2])!;
      expect(r.nAmostras, 2);
      expect(r.pesoInicial, closeTo(0.5, 1e-9));
      expect(r.pesoFinal, closeTo(2.5, 1e-9));
      expect(r.ganhoTotal, closeTo(2.0, 1e-9));
      expect(r.dias, 14);
      expect(r.ganhoDiarioMedio, closeTo(2.0 / 14, 1e-9));
    });

    test('ganho diário médio com datas iguais não quebra (divisão por zero)', () {
      final b1 = _bio('1', DateTime(2026, 1, 10), 0.05, 100);
      final b2 = _bio('2', DateTime(2026, 1, 10), 0.09, 100);

      final r = resumirCrescimento([b1, b2])!;
      expect(r.dias, 0);
      expect(r.ganhoDiarioMedio, 0);
    });
  });
}
