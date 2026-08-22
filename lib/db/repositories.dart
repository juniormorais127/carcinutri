import 'package:sembast/sembast.dart';

import '../domain/modelos.dart';

/// Acesso aos viveiros no banco local.
class ViveiroRepositorio {
  final Database _db;
  final StoreRef<String, Object?> _store;
  ViveiroRepositorio(this._db, this._store);

  Future<List<Viveiro>> listar() async {
    final registros = await _store.find(_db);
    final v = registros
        .map((r) => Viveiro.fromJson(Map<String, Object?>.from(r.value as Map)))
        .toList();
    v.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return v;
  }

  Future<void> salvar(Viveiro v) async {
    await _store.record(v.id).put(_db, v.toJson());
  }

  Future<void> remover(String id) async {
    await _store.record(id).delete(_db);
  }
}

/// Acesso ao histórico de cálculos no banco local.
class CalculoRepositorio {
  final Database _db;
  final StoreRef<String, Object?> _store;
  CalculoRepositorio(this._db, this._store);

  Future<List<Calculo>> listar({String? viveiroId}) async {
    final registros = await _store.find(
      _db,
      finder: viveiroId == null
          ? null
          : Finder(filter: Filter.equals('viveiroId', viveiroId)),
    );
    final c = registros
        .map((r) => Calculo.fromJson(Map<String, Object?>.from(r.value as Map)))
        .toList();
    c.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return c;
  }

  Future<void> salvar(Calculo c) async {
    await _store.record(c.id).put(_db, c.toJson());
  }

  Future<void> remover(String id) async {
    await _store.record(id).delete(_db);
  }
}

/// Acesso ao histórico de biometrias no banco local.
class BiometriaRepositorio {
  final Database _db;
  final StoreRef<String, Object?> _store;
  BiometriaRepositorio(this._db, this._store);

  Future<List<Biometria>> listar({String? viveiroId}) async {
    final registros = await _store.find(
      _db,
      finder: viveiroId == null
          ? null
          : Finder(filter: Filter.equals('viveiroId', viveiroId)),
    );
    final b = registros
        .map(
            (r) => Biometria.fromJson(Map<String, Object?>.from(r.value as Map)))
        .toList();
    b.sort((a, b) => b.data.compareTo(a.data));
    return b;
  }

  Future<void> salvar(Biometria b) async {
    await _store.record(b.id).put(_db, b.toJson());
  }

  Future<void> remover(String id) async {
    await _store.record(id).delete(_db);
  }
}

/// Acesso ao histórico de qualidade de água no banco local.
class QualidadeAguaRepositorio {
  final Database _db;
  final StoreRef<String, Object?> _store;
  QualidadeAguaRepositorio(this._db, this._store);

  Future<List<QualidadeAgua>> listar({String? viveiroId}) async {
    final registros = await _store.find(
      _db,
      finder: viveiroId == null
          ? null
          : Finder(filter: Filter.equals('viveiroId', viveiroId)),
    );
    final q = registros
        .map((r) =>
            QualidadeAgua.fromJson(Map<String, Object?>.from(r.value as Map)))
        .toList();
    q.sort((a, b) => b.data.compareTo(a.data));
    return q;
  }

  Future<void> salvar(QualidadeAgua q) async {
    await _store.record(q.id).put(_db, q.toJson());
  }

  Future<void> remover(String id) async {
    await _store.record(id).delete(_db);
  }
}
