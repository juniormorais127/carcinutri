import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/repositories.dart';
import '../domain/modelos.dart';

/// Estado global do app: viveiros + histórico de cálculos, tudo local.
class AppState extends ChangeNotifier {
  AppState(this.db)
      : viveirosRepo = ViveiroRepositorio(db.db, db.viveiros),
        calculosRepo = CalculoRepositorio(db.db, db.calculos),
        biometriasRepo = BiometriaRepositorio(db.db, db.biometrias),
        qualidadeAguaRepo =
            QualidadeAguaRepositorio(db.db, db.qualidadeAgua),
        mareRepo = MareRepositorio(db.db, db.mare);

  final AppDatabase db;
  final ViveiroRepositorio viveirosRepo;
  final CalculoRepositorio calculosRepo;
  final BiometriaRepositorio biometriasRepo;
  final QualidadeAguaRepositorio qualidadeAguaRepo;
  final MareRepositorio mareRepo;

  List<Viveiro> _viveiros = [];
  List<Calculo> _calculos = [];
  List<Biometria> _biometrias = [];
  List<QualidadeAgua> _qualidadeAgua = [];
  bool _carregado = false;

  List<Viveiro> get viveiros => List.unmodifiable(_viveiros);
  List<Calculo> get calculos => List.unmodifiable(_calculos);
  bool get carregado => _carregado;

  Future<void> carregar() async {
    _viveiros = await viveirosRepo.listar();
    _calculos = await calculosRepo.listar();
    _biometrias = await biometriasRepo.listar();
    _qualidadeAgua = await qualidadeAguaRepo.listar();
    _carregado = true;
    notifyListeners();
  }

  Viveiro? porId(String? id) {
    if (id == null) return null;
    for (final v in _viveiros) {
      if (v.id == id) return v;
    }
    return null;
  }

  List<Calculo> calculosDoViveiro(String? viveiroId) {
    if (viveiroId == null) return _calculos;
    return _calculos.where((c) => c.viveiroId == viveiroId).toList();
  }

  Future<void> salvarViveiro(Viveiro v) async {
    await viveirosRepo.salvar(v);
    _viveiros = await viveirosRepo.listar();
    notifyListeners();
  }

  Future<void> removerViveiro(String id) async {
    await viveirosRepo.remover(id);
    final calcVinculados = _calculos.where((c) => c.viveiroId == id).toList();
    for (final c in calcVinculados) {
      await calculosRepo.remover(c.id);
    }
    final bioVinculadas = _biometrias.where((b) => b.viveiroId == id).toList();
    for (final b in bioVinculadas) {
      await biometriasRepo.remover(b.id);
    }
    final qaVinculados =
        _qualidadeAgua.where((q) => q.viveiroId == id).toList();
    for (final q in qaVinculados) {
      await qualidadeAguaRepo.remover(q.id);
    }
    await carregar();
  }

  Future<void> salvarCalculo(Calculo c) async {
    await calculosRepo.salvar(c);
    _calculos = await calculosRepo.listar();
    notifyListeners();
  }

  Future<void> removerCalculo(String id) async {
    await calculosRepo.remover(id);
    _calculos = await calculosRepo.listar();
    notifyListeners();
  }

  List<Biometria> listarBiometrias(String? viveiroId) {
    if (viveiroId == null) return List.unmodifiable(_biometrias);
    return _biometrias.where((b) => b.viveiroId == viveiroId).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  Biometria? ultimaBiometria(String? viveiroId) {
    if (viveiroId == null) return null;
    Biometria? ultima;
    for (final b in _biometrias) {
      if (b.viveiroId != viveiroId) continue;
      if (ultima == null || b.data.isAfter(ultima.data)) ultima = b;
    }
    return ultima;
  }

  Future<void> salvarBiometria(Biometria b) async {
    await biometriasRepo.salvar(b);
    _biometrias = await biometriasRepo.listar();
    notifyListeners();
  }

  Future<void> removerBiometria(String id) async {
    await biometriasRepo.remover(id);
    _biometrias = await biometriasRepo.listar();
    notifyListeners();
  }

  List<QualidadeAgua> listarQualidadeAgua(String? viveiroId) {
    if (viveiroId == null) return List.unmodifiable(_qualidadeAgua);
    return _qualidadeAgua.where((q) => q.viveiroId == viveiroId).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  QualidadeAgua? ultimaQualidadeAgua(String? viveiroId) {
    if (viveiroId == null) return null;
    QualidadeAgua? ultima;
    for (final q in _qualidadeAgua) {
      if (q.viveiroId != viveiroId) continue;
      if (ultima == null || q.data.isAfter(ultima.data)) ultima = q;
    }
    return ultima;
  }

  Future<void> salvarQualidadeAgua(QualidadeAgua q) async {
    await qualidadeAguaRepo.salvar(q);
    _qualidadeAgua = await qualidadeAguaRepo.listar();
    notifyListeners();
  }
}
