import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app.dart';
import 'data/sync_api.dart';
import 'db/app_database.dart';
import 'state/app_state.dart';
import 'state/auth_state.dart';
import 'state/sync_service.dart';

Future<void> main() async {
  // Usa rotas com '#' (#/projecao) para o app funcionar em qualquer host
  // estático (GitHub Pages, Netlify etc.), inclusive com refresh em rota interna.
  setHashUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.abrir();
  final state = AppState(db);
  await state.carregar();

  final auth = AuthState();
  await auth.restaurar();

  final sync = SyncService(api: SyncApi(), auth: auth, app: state);
  sync.iniciarMonitor();
  // Se já houver sessão e internet, sincroniza registros pendentes ao abrir.
  if (auth.autenticado) {
    sync.sincronizar();
  }

  runApp(CarciniApp(state: state, auth: auth, sync: sync));
}
