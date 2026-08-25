import 'package:carcini_calc/domain/arracoamento_inicial.dart';
import 'package:carcini_calc/domain/calculadoras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alimentação Inicial (Tabela 19 ABCC)', () {
    test('Dia 1 para 1 milhão de PLs em direto quente', () {
      final rec = calcularAlimentacaoInicial(
        dia: 1,
        nPls: 1000000,
        tipoPovoamento: TipoPovoamentoInicial.diretoQuente,
      );

      expect(rec.dia, 1);
      expect(rec.semana, 1);
      expect(rec.taxaTabela19KgPorMilhao, 20.0);
      expect(rec.racaoDiariaKg, 20.0);
      expect(rec.tratosSugeridos, 4);
      expect(rec.racaoPorTratoKg, 5.0);
      expect(rec.orientacaoManejo, contains('Semana 1'));
    });

    test('Dia 7 proporcional para 150.000 PLs em direto frio', () {
      // Dia 7 dirF = 26 kg / milhão
      // 26 * 0.15 = 3.9 kg/dia
      final rec = calcularAlimentacaoInicial(
        dia: 7,
        nPls: 150000,
        tipoPovoamento: TipoPovoamentoInicial.diretoFrio,
      );

      expect(rec.dia, 7);
      expect(rec.semana, 1);
      expect(rec.taxaTabela19KgPorMilhao, 26.0);
      expect(rec.racaoDiariaKg, closeTo(3.9, 0.001));
    });

    test('Dia 15 para 500.000 PLs em indireto quente', () {
      // Dia 15 indQ = 39 kg / milhão
      // 39 * 0.5 = 19.5 kg/dia
      final rec = calcularAlimentacaoInicial(
        dia: 15,
        nPls: 500000,
        tipoPovoamento: TipoPovoamentoInicial.indiretoQuente,
      );

      expect(rec.dia, 15);
      expect(rec.semana, 3);
      expect(rec.taxaTabela19KgPorMilhao, 39.0);
      expect(rec.racaoDiariaKg, 19.5);
      expect(rec.tratosSugeridos, 5);
      expect(rec.racaoPorTratoKg, 3.9);
      expect(rec.orientacaoManejo, contains('bandejas'));
    });

    test('Dia 24 (último dia da Tabela 19) para 300.000 PLs', () {
      // Dia 24 dirQ = 52 kg / milhão
      // 52 * 0.3 = 15.6 kg/dia
      final rec = calcularAlimentacaoInicial(
        dia: 24,
        nPls: 300000,
        tipoPovoamento: TipoPovoamentoInicial.diretoQuente,
      );

      expect(rec.dia, 24);
      expect(rec.semana, 4);
      expect(rec.taxaTabela19KgPorMilhao, 52.0);
      expect(rec.racaoDiariaKg, closeTo(15.6, 0.001));
    });

    test('Lança erro para dias fora de 1..24 ou nPls inválido', () {
      expect(
        () => calcularAlimentacaoInicial(dia: 0, nPls: 100000),
        throwsA(isA<CalculoInvalido>()),
      );
      expect(
        () => calcularAlimentacaoInicial(dia: 25, nPls: 100000),
        throwsA(isA<CalculoInvalido>()),
      );
      expect(
        () => calcularAlimentacaoInicial(dia: 5, nPls: 0),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Tabela 18 ABCC — Bandejas de Alimentação', () {
    test('Retorna número de bandejas/ha por densidade', () {
      expect(bandejasPorHaABCC(15), 20);
      expect(bandejasPorHaABCC(25), 25);
      expect(bandejasPorHaABCC(35), 35);
      expect(bandejasPorHaABCC(45), 45);
      expect(bandejasPorHaABCC(55), 50);
      expect(bandejasPorHaABCC(70), 60);
      expect(bandejasPorHaABCC(100), 70);
    });

    test('Calcula total de bandejas para a área do viveiro', () {
      // 35 cam/m² em 2.0 ha = 35 * 2 = 70 bandejas
      expect(calcularTotalBandejasViveiro(densidadeCamM2: 35, areaHa: 2.0), 70);
      // 25 cam/m² em 1.5 ha = 25 * 1.5 = 37.5 -> 38 bandejas
      expect(calcularTotalBandejasViveiro(densidadeCamM2: 25, areaHa: 1.5), 38);
    });
  });

  group('Ajuste de Arraçoamento por Consumo de Bandejas', () {
    test('Bandeja limpa (0% sobra) -> Aumento de +8%', () {
      final aj = calcularAjusteBandeja(
        sobraPercentual: 0.0,
        racaoTratoKg: 10.0,
      );

      expect(aj.acao, AcaoAjusteTrato.aumentar);
      expect(aj.fatorMultiplicador, 1.08);
      expect(aj.racaoAjustadaKg, closeTo(10.8, 0.001));
    });

    test('Consumo ideal (3% sobra) -> Mantém trato', () {
      final aj = calcularAjusteBandeja(
        sobraPercentual: 3.0,
        racaoTratoKg: 10.0,
      );

      expect(aj.acao, AcaoAjusteTrato.manter);
      expect(aj.fatorMultiplicador, 1.0);
      expect(aj.racaoAjustadaKg, 10.0);
    });

    test('Sobra leve (10%) -> Reduz 10%', () {
      final aj = calcularAjusteBandeja(
        sobraPercentual: 10.0,
        racaoTratoKg: 10.0,
      );

      expect(aj.acao, AcaoAjusteTrato.reduzirLeve);
      expect(aj.fatorMultiplicador, 0.90);
      expect(aj.racaoAjustadaKg, 9.0);
    });

    test('Sobra moderada (20%) -> Reduz 25%', () {
      final aj = calcularAjusteBandeja(
        sobraPercentual: 20.0,
        racaoTratoKg: 10.0,
      );

      expect(aj.acao, AcaoAjusteTrato.reduzirModerada);
      expect(aj.fatorMultiplicador, 0.75);
      expect(aj.racaoAjustadaKg, 7.5);
    });

    test('Sobra excessiva (35%) -> Corta 50%', () {
      final aj = calcularAjusteBandeja(
        sobraPercentual: 35.0,
        racaoTratoKg: 10.0,
      );

      expect(aj.acao, AcaoAjusteTrato.suspenderOuCortar);
      expect(aj.fatorMultiplicador, 0.50);
      expect(aj.racaoAjustadaKg, 5.0);
    });

    test('Oxigênio crítico (< 3.5 mg/L) prevalece sobre sobra baixa', () {
      final aj = calcularAjusteBandeja(
        sobraPercentual: 0.0, // mesmo limpa
        racaoTratoKg: 10.0,
        oxigenioDissolvidoMgL: 2.8, // hipóxia severa
      );

      expect(aj.acao, AcaoAjusteTrato.suspenderOuCortar);
      expect(aj.fatorMultiplicador, 0.5);
      expect(aj.racaoAjustadaKg, 5.0);
      expect(aj.justificativa, contains('Oxigênio Crítico'));
    });
  });
}
