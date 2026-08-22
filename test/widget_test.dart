import 'package:carcini_calc/domain/calculadoras.dart';
import 'package:carcini_calc/widgets/result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResultCard renderiza o item destacado', (tester) async {
    final resultado = ResultadoCalculo([
      ItemResultado('Rotulo normal', 'valor'),
      ItemResultado('Densidade', '1 cam/m²', destaque: true),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ResultCard(resultado: resultado)),
    ));

    expect(find.text('1 cam/m²'), findsOneWidget);
    expect(find.text('Densidade'), findsOneWidget);
  });
}
