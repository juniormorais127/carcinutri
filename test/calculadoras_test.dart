import 'package:carcini_calc/domain/calculadoras.dart';
import 'package:carcini_calc/domain/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extrai o primeiro número (aceita vírgula/ponto) do início de uma string.
double _num(String s) {
  final m = RegExp(r'^(\d+(?:[.,]\d+)?)').firstMatch(s);
  return double.parse(m!.group(1)!.replaceAll(',', '.'));
}

DefinicaoCalculadora _def(TipoCalculadora t) => calculadorasPorTipo[t]!;

ItemResultado _principal(ResultadoCalculo r) {
  for (final i in r.itens) {
    if (i.destaque) return i;
  }
  fail('Nenhum item destacado');
}

void main() {
  group('Densidade de estocagem', () {
    test('calcula camarões por m²', () {
      final r = _def(TipoCalculadora.densidade)
          .calcular({'n_camaroes': 100000, 'area': 1});
      final p = _principal(r);
      expect(_num(p.valor), closeTo(10, 0.001));
      expect(p.valor, contains('cam/m²'));
    });

    test('rejeita área zero', () {
      expect(
        () => _def(TipoCalculadora.densidade)
            .calcular({'n_camaroes': 100, 'area': 0}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Povoamento', () {
    test('calcula camarões a povoar', () {
      final r = _def(TipoCalculadora.povoamento)
          .calcular({'area': 1, 'densidade': 10});
      expect(_num(_principal(r).valor), closeTo(100000, 0.001));
    });

    test('rejeita densidade zero', () {
      expect(
        () => _def(TipoCalculadora.povoamento)
            .calcular({'area': 1, 'densidade': 0}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Sobrevivência', () {
    test('calcula percentual de vivos', () {
      final r = _def(TipoCalculadora.sobrevivencia)
          .calcular({'n_inicial': 10000, 'n_atual': 8000});
      expect(_num(_principal(r).valor), closeTo(80, 0.001));
      expect(_principal(r).valor, contains('%'));
    });

    test('rejeita nº inicial zero', () {
      expect(
        () => _def(TipoCalculadora.sobrevivencia)
            .calcular({'n_inicial': 0, 'n_atual': 100}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Peso médio', () {
    test('converte kg da amostra em gramas por camarão', () {
      final r = _def(TipoCalculadora.pesoMedio)
          .calcular({'peso_amostra': 2, 'n_amostrado': 200});
      expect(_num(_principal(r).valor), closeTo(10, 0.001));
      expect(_principal(r).valor, contains('g'));
    });

    test('rejeita amostra vazia', () {
      expect(
        () => _def(TipoCalculadora.pesoMedio)
            .calcular({'peso_amostra': 2, 'n_amostrado': 0}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Ganho de peso', () {
    test('subtrai peso inicial do atual', () {
      final r = _def(TipoCalculadora.ganhoPeso)
          .calcular({'peso_inicial': 5, 'peso_atual': 12});
      expect(_num(_principal(r).valor), closeTo(7, 0.001));
    });
  });

  group('Crescimento semanal', () {
    test('divide ganho pelo nº de semanas', () {
      final r = _def(TipoCalculadora.crescimentoSemanal)
          .calcular({'peso_anterior': 5, 'peso_atual': 12, 'semanas': 1});
      expect(_num(_principal(r).valor), closeTo(7, 0.001));
      expect(_principal(r).valor, contains('g/semana'));
    });

    test('rejeita intervalo zero', () {
      expect(
        () => _def(TipoCalculadora.crescimentoSemanal)
            .calcular({'peso_anterior': 5, 'peso_atual': 12, 'semanas': 0}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('TCE', () {
    test('calcula taxa específica em % ao dia', () {
      // ln(27.1828/10)/100*100 ≈ 1 %/dia
      final r = _def(TipoCalculadora.tce)
          .calcular({'peso_inicial': 10, 'peso_final': 27.1828, 'dias': 100});
      expect(_num(_principal(r).valor), closeTo(1, 0.01));
      expect(_principal(r).valor, contains('%/dia'));
    });

    test('rejeita peso inicial zero', () {
      expect(
        () => _def(TipoCalculadora.tce)
            .calcular({'peso_inicial': 0, 'peso_final': 10, 'dias': 5}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Biomassa', () {
    test('estima kg totais no viveiro', () {
      // 10 cam/m² × 1 ha × 10000 × 10 g / 1000 = 1000 kg
      final r = _def(TipoCalculadora.biomassa).calcular(
          {'densidade': 10, 'area': 1, 'peso_medio': 10});
      expect(_num(_principal(r).valor), closeTo(1000, 0.001));
      expect(_principal(r).valor, contains('kg'));
    });
  });

  group('Arraçoamento', () {
    test('calcula ração por dia a partir da taxa', () {
      final r = _def(TipoCalculadora.arracoamento)
          .calcular({'biomassa': 1000, 'taxa': 5});
      expect(_num(_principal(r).valor), closeTo(50, 0.001));
      expect(_principal(r).valor, contains('kg/dia'));
    });
  });

  group('Conversão alimentar (CAA)', () {
    test('divide ração consumida pelo ganho', () {
      final r = _def(TipoCalculadora.caa)
          .calcular({'racao': 100, 'ganho_biomassa': 50});
      expect(_num(_principal(r).valor), closeTo(2, 0.001));
    });

    test('rejeita ganho zero', () {
      expect(
        () => _def(TipoCalculadora.caa)
            .calcular({'racao': 100, 'ganho_biomassa': 0}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Produtividade', () {
    test('calcula kg por hectare', () {
      final r = _def(TipoCalculadora.produtividade)
          .calcular({'biomassa': 1000, 'area': 1});
      expect(_num(_principal(r).valor), closeTo(1000, 0.001));
      expect(_principal(r).valor, contains('kg/ha'));
    });
  });

  group('Renovação de água', () {
    test('calcula percentual renovado', () {
      final r = _def(TipoCalculadora.renovacaoAgua)
          .calcular({'volume_total': 1000, 'volume_renovado': 100});
      expect(_num(_principal(r).valor), closeTo(10, 0.001));
      expect(_principal(r).valor, contains('%'));
    });

    test('rejeita volume total zero', () {
      expect(
        () => _def(TipoCalculadora.renovacaoAgua)
            .calcular({'volume_total': 0, 'volume_renovado': 100}),
        throwsA(isA<CalculoInvalido>()),
      );
    });
  });

  group('Registro', () {
    test('todas as 12 calculadoras estão registradas e únicas', () {
      expect(todasCalculadoras.length, 12);
      final ids = todasCalculadoras.map((d) => d.tipo).toSet();
      expect(ids.length, 12);
      for (final t in TipoCalculadora.values) {
        expect(calculadorasPorTipo.containsKey(t), isTrue);
      }
    });
  });
}
