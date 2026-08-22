import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app.dart';
import 'db/app_database.dart';
import 'state/app_state.dart';

Future<void> main() async {
  // Usa rotas com '#' (#/projecao) para o app funcionar em qualquer host
  // estático (GitHub Pages, Netlify etc.), inclusive com refresh em rota interna.
  setHashUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.abrir();
  final state = AppState(db);
  await state.carregar();
  runApp(AquacensoApp(state: state));
}
