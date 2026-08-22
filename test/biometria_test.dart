import 'package:carcini_calc/domain/calculadoras.dart';
import 'package:carcini_calc/domain/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Biometria', () {
    test('calcula peso médio a partir de amostra e contagem', () {
      // 2 kg de amostra com 200 camarões = 10 g/camarão
      final b = Biometria(
        id: '1',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 22),
        pesoAmostraKg: 2,
        nAmostrado: 200,
      );
      expect(b.pesoMedio, closeTo(10, 0.001));
    });

    test('serializa e desserializa mantendo o peso médio', () {
      final b = Biometria(
        id: '1',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 22),
        pesoAmostraKg: 1.5,
        nAmostrado: 300,
      );
      final c = Biometria.fromJson(Map<String, Object?>.from(b.toJson()));
      expect(c.id, b.id);
      expect(c.viveiroId, b.viveiroId);
      expect(c.pesoMedio, closeTo(b.pesoMedio, 0.001));
    });

    test('rejeita contagem zero', () {
      expect(
        () => Biometria(
          id: '1',
          viveiroId: 'v1',
          data: DateTime(2026, 8, 22),
          pesoAmostraKg: 1,
          nAmostrado: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Lógica derivada', () {
    test('calcularBiomassa converte densidade, área e peso em kg', () {
      // 10 cam/m² × 1 ha × 10000 × 10 g / 1000 = 1000 kg
      expect(calcularBiomassa(10, 1, 10), closeTo(1000, 0.001));
    });

    test('racaoPorDia aplica a taxa sobre a biomassa', () {
      expect(racaoPorDia(1000, 5), closeTo(50, 0.001));
      expect(racaoPorDia(500, 3), closeTo(15, 0.001));
    });
  });

  group('Encadeamento biometria → biomassa → ração', () {
    test('fluxo completo com valores consistentes', () {
      final b = Biometria(
        id: '1',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 22),
        pesoAmostraKg: 2,
        nAmostrado: 200, // peso médio 10 g
      );
      final biomassa = calcularBiomassa(10, 1, b.pesoMedio);
      expect(biomassa, closeTo(1000, 0.001));
      expect(racaoPorDia(biomassa, 5), closeTo(50, 0.001));
    });
  });
}
