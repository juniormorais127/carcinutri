import 'package:carcini_calc/domain/arracoamento.dart';
import 'package:carcini_calc/domain/calculadoras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pontos exatos da tabela FAO (taxa por peso)', () {
    test('limites da tabela batem com os valores de referência', () {
      double taxa(double peso) => recomendarArracoamento(
            especie: especieVannamei,
            pesoMedio: peso,
            nVivos: 50000,
          ).taxaPct!;

      expect(taxa(2.5), closeTo(5.8, 0.001));
      expect(taxa(3.5), closeTo(4.8, 0.001));
      expect(taxa(8.0), closeTo(3.2, 0.001));
      expect(taxa(12.5), closeTo(2.6, 0.001));
      expect(taxa(17.5), closeTo(2.2, 0.001));
      expect(taxa(22.0), closeTo(1.8, 0.001));
    });

    test('interpolação linear dentro de uma faixa', () {
      // Faixa 3,5–8 g: 4,8% → 3,2%. No meio (5,75 g) → 4,0%.
      final f = faixaParaPeso(especieVannamei, 5.75)!;
      expect(interpolateFeedingRate(f, 5.75), closeTo(4.0, 0.001));

      // Faixa 8–12,5 g: 3,2% → 2,6%. No meio (10,25 g) → 2,9%.
      final f2 = faixaParaPeso(especieVannamei, 10.25)!;
      expect(interpolateFeedingRate(f2, 10.25), closeTo(2.9, 0.001));
    });
  });

  group('Funções derivadas', () {
    test('biomassa = nº vivos × peso ÷ 1000 (50k × 10 g = 500 kg)', () {
      expect(calcularBiomassaViva(50000, 10), closeTo(500, 0.001));
    });

    test('sobrevivência: 50k povoados × 80% = 40k vivos', () {
      expect(calcularCamaroesVivos(50000, 80), 40000);
    });

    test('ração por trato = ração diária ÷ nº de tratos', () {
      expect(calcularRacaoPorTrato(15, 5), closeTo(3, 0.001));
    });
  });

  group('recomendarArracoamento dentro da faixa', () {
    final r = recomendarArracoamento(
      especie: especieVannamei,
      pesoMedio: 10,
      nVivos: 50000,
    );

    test('biomassa e ração conferem (reusa racaoPorDia)', () {
      expect(r.biomassaKg, closeTo(500, 0.001));
      expect(r.taxaPct, closeTo(2.9333, 0.01));
      // ração = biomassa × taxa ÷ 100
      expect(r.racaoDiariaKg, closeTo(racaoPorDia(500, r.taxaPct!), 0.001));
    });

    test('tratos padrão = mínimo da faixa e ração por trato correta', () {
      expect(r.tratosMin, 5);
      expect(r.tratosMax, 5);
      expect(r.nTratos, 5);
      expect(r.racaoPorTratoKg,
          closeTo(r.racaoDiariaKg / 5, 0.001));
    });

    test('status ok e bandeja preenchida', () {
      expect(r.status, 'ok');
      expect(r.bandejaPct, 1.0);
      expect(r.bandejaTempoH, 1.45);
      expect(r.aviso, isNull);
    });

    test('taxa manual dentro da faixa é respeitada e rotulada', () {
      final m = recomendarArracoamento(
        especie: especieVannamei,
        pesoMedio: 10,
        nVivos: 50000,
        taxaManual: 3.0,
      );
      expect(m.taxaPct, closeTo(3.0, 0.001));
      expect(m.taxaManual, isTrue);
      expect(m.racaoDiariaKg, closeTo(racaoPorDia(500, 3.0), 0.001));
    });
  });

  group('Fora da faixa (alerta técnico)', () {
    test('peso abaixo de 2,5 g → não extrapola', () {
      final r = recomendarArracoamento(
        especie: especieVannamei,
        pesoMedio: 1,
        nVivos: 50000,
      );
      expect(r.status, 'abaixo');
      expect(r.taxaPct, isNull);
      expect(r.racaoDiariaKg, 0);
      expect(r.aviso, isNotNull);
      expect(r.aviso, contains('berçário'));
    });

    test('peso acima de 22 g → usa 1,8% como limite superior', () {
      final r = recomendarArracoamento(
        especie: especieVannamei,
        pesoMedio: 25,
        nVivos: 50000,
      );
      expect(r.status, 'acima');
      expect(r.taxaPct, closeTo(1.8, 0.001));
      expect(r.taxaManual, isFalse);
      // biomassa = 50000 × 25 g = 1250 kg → ração = 1250 × 1,8% = 22,5 kg
      expect(r.racaoDiariaKg, closeTo(22.5, 0.001));
      expect(r.aviso, isNotNull);
    });

    test('peso acima de 22 g com taxa manual → usa a manual', () {
      final r = recomendarArracoamento(
        especie: especieVannamei,
        pesoMedio: 25,
        nVivos: 50000,
        taxaManual: 1.5,
      );
      expect(r.status, 'acima');
      expect(r.taxaPct, closeTo(1.5, 0.001));
      expect(r.taxaManual, isTrue);
      expect(r.racaoDiariaKg, closeTo(racaoPorDia(1250, 1.5), 0.001));
    });
  });

  group('Validações (CalculoInvalido)', () {
    void esperaErro(void Function() fn) {
      expect(fn, throwsA(isA<CalculoInvalido>()));
    }

    test('peso ≤ 0', () {
      esperaErro(() => recomendarArracoamento(
          especie: especieVannamei, pesoMedio: 0, nVivos: 50000));
    });

    test('nº de vivos ≤ 0', () {
      esperaErro(() => recomendarArracoamento(
          especie: especieVannamei, pesoMedio: 10, nVivos: 0));
    });

    test('taxa manual negativa', () {
      esperaErro(() => recomendarArracoamento(
          especie: especieVannamei,
          pesoMedio: 10,
          nVivos: 50000,
          taxaManual: -1));
    });

    test('nº de tratos fora da faixa da espécie', () {
      // Peso 10 g → faixa 8–12,5 g, tratos 5–5.
      esperaErro(() => recomendarArracoamento(
          especie: especieVannamei,
          pesoMedio: 10,
          nVivos: 50000,
          nTratos: 8));
    });

    test('sobrevivência fora de 0–100%', () {
      expect(() => calcularCamaroesVivos(50000, 150),
          throwsA(isA<CalculoInvalido>()));
      expect(() => calcularCamaroesVivos(50000, -5),
          throwsA(isA<CalculoInvalido>()));
    });

    test('povoados ≤ 0', () {
      expect(() => calcularCamaroesVivos(0, 80),
          throwsA(isA<CalculoInvalido>()));
    });
  });
}
