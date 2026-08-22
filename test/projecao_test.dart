import 'package:carcini_calc/domain/modelos.dart';
import 'package:carcini_calc/domain/projecao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Curva de crescimento (pesoEsperado)', () {
    test('dia 0 = peso inicial e dia 70 = peso alvo', () {
      expect(pesoEsperado(0), closeTo(0.05, 0.001));
      expect(pesoEsperado(70), closeTo(9.5, 0.001));
    });

    test('peso estritamente crescente ao longo do ciclo', () {
      double anterior = 0;
      for (var d = 0; d <= 70; d++) {
        final p = pesoEsperado(d);
        expect(p, greaterThan(anterior));
        anterior = p;
      }
    });

    test('meio do ciclo ~ metade do peso alvo (perfil realista)', () {
      // dia 42 ≈ 53% do peso aos 70 dias = ~5 g
      expect(pesoEsperado(42), closeTo(5.06, 0.15));
      expect(pesoEsperado(35), closeTo(3.55, 0.2));
    });
  });

  group('Taxa de arraçoamento (FAO)', () {
    test('limite inferior (5,8%) e pontos da tabela', () {
      // Abaixo de 2,5 g usa 5,8% como teto (fase inicial do ciclo).
      expect(taxaAlimentacao(0.5), 5.8);
      expect(taxaAlimentacao(1.5), 5.8);
      expect(taxaAlimentacao(2.5), 5.8);
      expect(taxaAlimentacao(3.5), 4.8);
    });

    test('interpolação linear entre os pontos FAO', () {
      // 4,5 g em [3,5;8]: 4,8 → 3,2  ⇒ 4,8 + (1/4,5)×(-1,6) ≈ 4,444
      expect(taxaAlimentacao(4.5), closeTo(4.444, 0.001));
      // 7 g ⇒ 4,8 + (3,5/4,5)×(-1,6) ≈ 3,556
      expect(taxaAlimentacao(7), closeTo(3.556, 0.001));
      // 9 g em [8;12,5]: 3,2 → 2,6 ⇒ 3,2 + (1/4,5)×(-0,6) ≈ 3,067
      expect(taxaAlimentacao(9), closeTo(3.067, 0.001));
      // 11 g ⇒ 3,2 + (3/4,5)×(-0,6) = 2,8
      expect(taxaAlimentacao(11), closeTo(2.8, 0.001));
      // 13 g em [12,5;17,5]: 2,6 → 2,2 ⇒ 2,56
      expect(taxaAlimentacao(13), closeTo(2.56, 0.001));
      // 16 g ⇒ 2,32
      expect(taxaAlimentacao(16), closeTo(2.32, 0.001));
      // 20 g em [17,5;22]: 2,2 → 1,8 ⇒ ≈ 1,978
      expect(taxaAlimentacao(20), closeTo(1.978, 0.001));
    });
  });

  group('projetarCiclo', () {
    // 1 ha, 10 cam/m², sobrevivência 100% → 100.000 camarões.
    final c = projetarCiclo(
      areaHa: 1,
      densidade: 10,
      sobrevivenciaPct: 100,
    );

    test('nº de camarões correto', () {
      expect(c.nCamaroes, 100000);
    });

    test('ração do dia 0 e do dia 70', () {
      // dia 0: biomassa = 100000 × 0,05 / 1000 = 5 kg; taxa 5,8% (teto) → 0,29 kg
      expect(c.dias.first.racaoKgDia, closeTo(0.29, 0.001));
      // dia 70: peso 9,5 g → biomassa 950 kg; taxa FAO (9,5 g) = 3,0% → 28,5 kg
      expect(c.dias.last.racaoKgDia, closeTo(28.5, 0.001));
    });

    test('acumulado final = ração total do ciclo', () {
      expect(c.dias.last.racaoAcumuladaKg, closeTo(c.racaoTotalKg, 0.01));
    });

    test('ração média/dia = total / 70', () {
      expect(c.racaoMediaDiaKg, closeTo(c.racaoTotalKg / 70, 0.001));
    });

    test('FCA = ração total / biomassa final', () {
      const biomassaFinal = 100000 * 9.5 / 1000; // 950 kg
      expect(c.fca, closeTo(c.racaoTotalKg / biomassaFinal, 0.01));
    });
  });

  group('compararComEsperado', () {
    test('dentro de ±10% → esperado', () {
      final r = compararComEsperado(pesoReal: 10.5, pesoEsperado: 10);
      expect(r.status, 'esperado');
      expect(r.difPct, closeTo(5, 0.001));
    });

    test('acima de 10% → acima', () {
      final r = compararComEsperado(pesoReal: 12, pesoEsperado: 10);
      expect(r.status, 'acima');
    });

    test('abaixo de -10% → abaixo', () {
      final r = compararComEsperado(pesoReal: 8, pesoEsperado: 10);
      expect(r.status, 'abaixo');
      expect(r.difG, closeTo(-2, 0.001));
    });
  });

  group('Viveiro com dataPovoamento', () {
    test('serializa e desserializa a data de povoamento', () {
      final v = Viveiro(
        id: '1',
        nome: 'Viveiro A',
        areaHa: 1.5,
        densidadePadrao: 12,
        marcaRacao: 'Guabi',
        dataPovoamento: DateTime(2026, 7, 1),
        criadoEm: DateTime(2026, 7, 1),
      );
      final c = Viveiro.fromJson(Map<String, Object?>.from(v.toJson()));
      expect(c.dataPovoamento, DateTime(2026, 7, 1));
      expect(c.marcaRacao, 'Guabi');
      expect(c.densidadePadrao, 12);
    });

    test('dataPovoamento nulo sobrevive ao round-trip', () {
      final v = Viveiro(
        id: '1',
        nome: 'Viveiro B',
        areaHa: 1,
        criadoEm: DateTime(2026, 7, 1),
      );
      final c = Viveiro.fromJson(Map<String, Object?>.from(v.toJson()));
      expect(c.dataPovoamento, isNull);
    });
  });
}
