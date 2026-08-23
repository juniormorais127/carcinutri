import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

import 'db_factory.dart';

/// Abre o banco local (sembast) — IndexedDB na web, arquivo no mobile/desktop.
class AppDatabase {
  AppDatabase._(this._db);
  final Database _db;

  static const _nome = 'carcini_calc.db';
  static const _versao = 1;

  static Future<AppDatabase> abrir() async {
    final path = await _resolverPath();
    final db = await databaseFactory.openDatabase(path, version: _versao);
    return AppDatabase._(db);
  }

  static Future<String> _resolverPath() async {
    if (kIsWeb) return _nome; // vira o nome do banco no IndexedDB
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _nome);
  }

  /// Cliente de banco usado nas operações dos repositórios.
  Database get db => _db;

  StoreRef<String, Object?> get viveiros =>
      stringMapStoreFactory.store('viveiros');

  StoreRef<String, Object?> get calculos =>
      stringMapStoreFactory.store('calculos');

  StoreRef<String, Object?> get biometrias =>
      stringMapStoreFactory.store('biometrias');

  StoreRef<String, Object?> get qualidadeAgua =>
      stringMapStoreFactory.store('qualidade_agua');

  StoreRef<String, Object?> get mare =>
      stringMapStoreFactory.store('mare');
}
