import 'package:carcini_calc/domain/modelos.dart';
import 'package:carcini_calc/domain/painel.dart';
import 'package:flutter_test/flutter_test.dart';

final _v = Viveiro(
  id: 'v1',
  nome: 'Viveiro 1',
  areaHa: 1.0,
  densidadePadrao: 50,
  dataPovoamento: DateTime(2026, 8, 1),
  criadoEm: DateTime(2026, 8, 1),
);

Biometria _bio(DateTime data, double pesoG) => Biometria(
      id: 'b${data.millisecondsSinceEpoch}',
      viveiroId: 'v1',
      data: data,
      pesoAmostraKg: pesoG * 100 / 1000, // n=100 → pesoMedio = pesoG
      nAmostrado: 100,
    );

void main() {
  group('resumirViveiro', () {
    final bio = [
      _bio(DateTime(2026, 8, 1), 4),
      _bio(DateTime(2026, 8, 20), 10),
    ];
    final agora = DateTime(2026, 8, 23);

    test('calcula biomassa, ração do dia e idade', () {
      final r = resumirViveiro(_v, bio, [], agora: agora);
      expect(r.pesoMedioG, 10); // última biometria
      expect(r.idadeDias, 22); // 23/08 - 01/08
      // biomassa = 50 × 1 × 10000 × 10 / 1000 = 5000 kg
      expect(r.biomassaKg, closeTo(5000, 1e-6));
      expect(r.racaoDiaKg, isNotNull);
      expect(r.racaoDiaKg!, greaterThan(0));
    });

    test('FCA projetado é positivo e plausível', () {
      final r = resumirViveiro(_v, bio, [], agora: agora);
      expect(r.fcaProjetado, isNotNull);
      expect(r.fcaProjetado!, greaterThan(0));
      expect(r.fcaProjetado!, lessThan(5));
    });

    test('sem biometria → biomassa e ração nulas', () {
      final r = resumirViveiro(_v, [], [], agora: agora);
      expect(r.pesoMedioG, isNull);
      expect(r.biomassaKg, isNull);
      expect(r.racaoDiaKg, isNull);
      expect(r.idadeDias, 22);
    });

    test('sem densidade → biomassa, ração e FCA nulas', () {
      final vSemDens = Viveiro(
        id: 'v2',
        nome: 'V2',
        areaHa: 2.0,
        dataPovoamento: DateTime(2026, 8, 1),
        criadoEm: DateTime(2026, 8, 1),
      );
      final r = resumirViveiro(vSemDens, bio, [], agora: agora);
      expect(r.biomassaKg, isNull);
      expect(r.racaoDiaKg, isNull);
      expect(r.fcaProjetado, isNull);
    });

    test('alerta quando qualidade de água sai da faixa', () {
      final qa = QualidadeAgua(
        id: 'q1',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 20),
        od: 3.0, // baixo (< 4)
        ph: 9.0, // alto (> 8.5)
        temperatura: 30,
      );
      final r = resumirViveiro(_v, bio, [qa], agora: agora);
      expect(r.alertasAgua, hasLength(2));
      expect(r.alertasAgua.join(' ').toLowerCase(), contains('od'));
      expect(r.alertasAgua.join(' ').toLowerCase(), contains('ph'));
    });

    test('qualidade de água dentro da faixa não gera alerta', () {
      final qa = QualidadeAgua(
        id: 'q2',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 20),
        od: 6.0,
        ph: 8.0,
        temperatura: 30,
        alcalinidade: 140,
      );
      final r = resumirViveiro(_v, bio, [qa], agora: agora);
      expect(r.alertasAgua, isEmpty);
    });
  });

  group('resumirGeral', () {
    test('soma área, biomassa e conta alertas', () {
      final a = resumirViveiro(_v, [_bio(DateTime(2026, 8, 20), 10)], [],
          agora: DateTime(2026, 8, 23));
      final v2 = Viveiro(
        id: 'v2',
        nome: 'V2',
        areaHa: 2.0,
        densidadePadrao: 50,
        criadoEm: DateTime(2026, 8, 1),
      );
      final b = resumirViveiro(v2, [_bio(DateTime(2026, 8, 20), 10)], [],
          agora: DateTime(2026, 8, 23));
      final g = resumirGeral([a, b]);
      expect(g.nViveiros, 2);
      expect(g.areaTotalHa, closeTo(3.0, 1e-6));
      expect(g.biomassaTotalKg, closeTo(15000, 1e-6)); // 5000 + 10000
      expect(g.racaoTotalDiaKg, isNotNull);
    });
  });

  group('preverDespesca', () {
    final bio = [
      _bio(DateTime(2026, 8, 1), 4),
      _bio(DateTime(2026, 8, 20), 10),
    ];

    test('estima data, produção e receita a partir do ganho diário', () {
      final p = preverDespesca(_v, bio,
          pesoAlvoG: 20, precoPorKg: 30, agora: DateTime(2026, 8, 23));
      expect(p, isNotNull);
      expect(p!.pesoAtualG, 10);
      expect(p.ganhoDiarioMedio, closeTo(6 / 19, 1e-9));
      expect(p.diasParaAlvo, greaterThan(0));
      // nCamaroes = 50 × 1 × 10000 × 0.8 = 400.000
      expect(p.nCamaroes, 400000);
      // produção = 400000 × 20 / 1000 = 8000 kg
      expect(p.producaoKg, closeTo(8000, 1e-6));
      // receita = 8000 × 30
      expect(p.receitaEstimada, closeTo(240000, 1e-6));
      expect(p.dataDespesca.isAfter(DateTime(2026, 8, 20)), isTrue);
    });

    test('retorna null com menos de 2 amostras', () {
      final p = preverDespesca(_v, [_bio(DateTime(2026, 8, 20), 10)],
          pesoAlvoG: 20, precoPorKg: 30);
      expect(p, isNull);
    });

    test('retorna null se o peso alvo já foi atingido', () {
      final p = preverDespesca(_v, bio,
          pesoAlvoG: 8, precoPorKg: 30, agora: DateTime(2026, 8, 23));
      expect(p, isNull);
    });

    test('sem densidade → produção e receita nulas, mas data calculada', () {
      final vSemDens = Viveiro(
        id: 'v2',
        nome: 'V2',
        areaHa: 2.0,
        dataPovoamento: DateTime(2026, 8, 1),
        criadoEm: DateTime(2026, 8, 1),
      );
      final p = preverDespesca(vSemDens, bio,
          pesoAlvoG: 20, precoPorKg: 30, agora: DateTime(2026, 8, 23));
      expect(p, isNotNull);
      expect(p!.nCamaroes, isNull);
      expect(p.producaoKg, isNull);
      expect(p.receitaEstimada, isNull);
      expect(p.dataDespesca.isAfter(DateTime(2026, 8, 20)), isTrue);
    });
  });

  group('alertasQualidadeAgua', () {
    test('amônia e nitrito altos alertam', () {
      final qa = QualidadeAgua(
        id: 'q',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 20),
        amonia: 0.3,
        nitrito: 2.0,
      );
      final a = alertasQualidadeAgua(qa);
      expect(a, hasLength(2));
    });
  });
}
