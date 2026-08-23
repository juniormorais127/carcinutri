import 'package:carcini_calc/screens/mare_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MareScreen monta sem erro e mostra os campos', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MareScreen()));
    // Primeiro frame + processar cálculo de initState.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Maré'), findsOneWidget); // AppBar
    expect(find.text('Amplitude da maré'), findsOneWidget);
    expect(find.text('Horário da preamar'), findsOneWidget);

    // O gráfico e a lista de marés ficam abaixo da dobra no viewport — rola.
    await tester.scrollUntilVisible(
      find.text('Marés de hoje'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Marés de hoje'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Altura da maré hoje'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Altura da maré hoje'), findsOneWidget);
  });
}
