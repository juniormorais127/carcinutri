import 'package:carcini_calc/domain/agua_quimica.dart';
import 'package:carcini_calc/domain/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Amônia Tóxica Não-Ionizada (NH3)', () {
    test('Calcula partição de NH3 em condições ideais e seguras', () {
      // TAN 0.5 mg/L, pH 7.5, Temp 28°C
      final av = calcularAmoniaToxica(
        amoniaTotalMgL: 0.5,
        ph: 7.5,
        temperaturaC: 28.0,
        salinidadePpt: 15.0,
      );

      expect(av.amoniaTotalMgL, 0.5);
      expect(av.ph, 7.5);
      expect(av.temperaturaC, 28.0);
      expect(av.fracaoNaoIonizada, greaterThan(0.01));
      expect(av.fracaoNaoIonizada, lessThan(0.04));
      expect(av.nh3ToxicoMgL, lessThan(0.05));
      expect(av.risco, NivelRiscoAmonia.seguro);
      expect(av.orientacao, contains('Nível seguro'));
    });

    test('Identifica nível de atenção com aumento de pH e amônia', () {
      // TAN 1.2 mg/L, pH 8.3, Temp 30°C
      final av = calcularAmoniaToxica(
        amoniaTotalMgL: 1.2,
        ph: 8.3,
        temperaturaC: 30.0,
        salinidadePpt: 15.0,
      );

      expect(av.nh3ToxicoMgL, greaterThanOrEqualTo(0.05));
      expect(av.nh3ToxicoMgL, lessThanOrEqualTo(0.18));
      expect(av.risco, isIn([NivelRiscoAmonia.atencao, NivelRiscoAmonia.critico]));
    });

    test('Identifica nível crítico sob pH elevado (pico vespertino)', () {
      // TAN 2.0 mg/L, pH 8.9, Temp 31°C
      final av = calcularAmoniaToxica(
        amoniaTotalMgL: 2.0,
        ph: 8.9,
        temperaturaC: 31.0,
        salinidadePpt: 20.0,
      );

      expect(av.nh3ToxicoMgL, greaterThan(0.10));
      expect(av.risco, NivelRiscoAmonia.critico);
      expect(av.orientacao, contains('CRÍTICO'));
    });

    test('Valida restrições de entrada (amônia negativa, pH fora de escala)', () {
      expect(
        () => calcularAmoniaToxica(amoniaTotalMgL: -1.0, ph: 7.5, temperaturaC: 28.0),
        throwsArgumentError,
      );
      expect(
        () => calcularAmoniaToxica(amoniaTotalMgL: 1.0, ph: 15.0, temperaturaC: 28.0),
        throwsArgumentError,
      );
      expect(
        () => calcularAmoniaToxica(amoniaTotalMgL: 1.0, ph: 7.5, temperaturaC: 70.0),
        throwsArgumentError,
      );
    });

    test('avaliarAmoniaRegistro integra com modelo QualidadeAgua', () {
      final qCompleto = QualidadeAgua(
        id: 'q1',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 25),
        amonia: 0.8,
        ph: 7.8,
        temperatura: 29.0,
      );
      final av = avaliarAmoniaRegistro(qCompleto);
      expect(av, isNotNull);
      expect(av!.amoniaTotalMgL, 0.8);

      final qIncompleto = QualidadeAgua(
        id: 'q2',
        viveiroId: 'v1',
        data: DateTime(2026, 8, 25),
        ph: 7.8, // sem amônia
      );
      expect(avaliarAmoniaRegistro(qIncompleto), isNull);
    });
  });

  group('Calagem e Correção de Solo/Água (Tabela 17 ABCC)', () {
    test('Dose da Tabela 17 para diferentes faixas de pH do solo', () {
      expect(doseCalcarioTabela17(4.5), 3500.0);
      expect(doseCalcarioTabela17(5.2), 2500.0);
      expect(doseCalcarioTabela17(5.8), 1750.0);
      expect(doseCalcarioTabela17(6.3), 1250.0);
      expect(doseCalcarioTabela17(7.0), 500.0);
    });

    test('Recomendação de calagem com calcário dolomítico e cal virgem', () {
      // 2 hectares com pH 4.8
      final recDolomitico = calcularCalagem(
        phSolo: 4.8,
        areaHa: 2.0,
        corretivo: TipoCorretivo.calcarioDolomitico,
      );
      expect(recDolomitico.doseBaseKgHa, 3500.0);
      expect(recDolomitico.doseAjustadaKgHa, 3500.0);
      expect(recDolomitico.quantidadeTotalKg, 7000.0);

      final recCalVirgem = calcularCalagem(
        phSolo: 4.8,
        areaHa: 2.0,
        corretivo: TipoCorretivo.calVirgem,
      );
      expect(recCalVirgem.doseBaseKgHa, 3500.0);
      expect(recCalVirgem.doseAjustadaKgHa, closeTo(3500.0 / 1.78, 0.1));
      expect(recCalVirgem.quantidadeTotalKg, closeTo(7000.0 / 1.78, 0.1));
    });

    test('calcularCorrecaoAlcalinidade com Bicarbonato de Sódio', () {
      // Elevar de 60 para 100 mg/L em 1 ha com 1m de profundidade
      // Volume = 10.000 m³. Deficit = 40 mg/L.
      // 40 * 1.68 * 10.000 / 1000 = 672 kg
      final kgBicarbonato = calcularCorrecaoAlcalinidade(
        alcalinidadeAtualMgL: 60.0,
        alcalinidadeAlvoMgL: 100.0,
        areaHa: 1.0,
        profundidadeMediaM: 1.0,
      );
      expect(kgBicarbonato, closeTo(672.0, 0.01));

      // Se atual >= alvo, retorna 0 kg
      final semDeficit = calcularCorrecaoAlcalinidade(
        alcalinidadeAtualMgL: 110.0,
        alcalinidadeAlvoMgL: 100.0,
        areaHa: 1.0,
      );
      expect(semDeficit, 0.0);
    });
  });
}
