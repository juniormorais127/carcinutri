import 'package:carcini_calc/data/mare_api.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _amostra() {
  return {
    'data': [
      {
        'year': 2026,
        'harbor_name': 'PORTO DE MUCURIPE FORTALEZA (ESTADO DO CEARÁ)',
        'state': 'ce',
        'months': [
          {
            'month': 8,
            'days': [
              {
                'weekday_name': 'domingo',
                'day': 23,
                'hours': [
                  {'hour': '01:08:00', 'level': 2.13},
                  {'hour': '07:47:00', 'level': 0.88},
                  {'hour': '14:04:00', 'level': 2.02},
                  {'hour': '19:55:00', 'level': 1.01},
                ],
              }
            ],
          }
        ],
      }
    ],
    'total': 1,
  };
}

void main() {
  group('parseTabua', () {
    final dias = parseTabua(_amostra(), 2026, 8);

    test('extrai o dia 23 com 4 níveis ordenados', () {
      final dia = dias[23];
      expect(dia, isNotNull);
      expect(dia!.niveis, hasLength(4));
      expect(dia.niveis.first.tempo.hour, 1);
      expect(dia.niveis.last.tempo.hour, 19);
      // ordenação por hora
      for (var i = 1; i < dia.niveis.length; i++) {
        expect(dia.niveis[i].tempo.isAfter(dia.niveis[i - 1].tempo), isTrue);
      }
    });

    test('marca picos como preamar e vales como baixa-mar', () {
      final dia = dias[23]!;
      final preamares = dia.eventos.where((e) => e.preamar).toList();
      final baixas = dia.eventos.where((e) => !e.preamar).toList();
      expect(preamares, hasLength(2));
      expect(baixas, hasLength(2));
      // preamares nos picos 01:08 (2.13) e 14:04 (2.02)
      expect(preamares.map((e) => e.tempo.hour), containsAll([1, 14]));
      // baixas nos vales 07:47 (0.88) e 19:55 (1.01)
      expect(baixas.map((e) => e.tempo.hour), containsAll([7, 19]));
    });

    test('dias vazios resultam em mapa vazio', () {
      final vazio = parseTabua({'data': []}, 2026, 8);
      expect(vazio, isEmpty);
    });
  });

  group('extração de eventos com 2 pontos', () {
    test('dois níveis alternam preamar/baixa', () {
      // público: monta JSON com 2 horas e verifica eventos
      final dias = parseTabua({
        'data': [
          {
            'year': 2026,
            'months': [
              {
                'month': 8,
                'days': [
                  {
                    'day': 1,
                    'hours': [
                      {'hour': '06:00:00', 'level': 2.0},
                      {'hour': '12:00:00', 'level': 0.5},
                    ],
                  }
                ],
              }
            ],
          }
        ]
      }, 2026, 8);
      final dia = dias[1]!;
      expect(dia.eventos.map((e) => e.preamar).toList(), [true, false]);
    });
  });
}
