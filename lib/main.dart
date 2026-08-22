import 'package:flutter/material.dart';

import 'app.dart';
import 'db/app_database.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.abrir();
  final state = AppState(db);
  await state.carregar();
  runApp(CarciniApp(state: state));
}
