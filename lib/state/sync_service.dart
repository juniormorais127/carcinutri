import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/sync_api.dart';
import 'app_state.dart';
import 'auth_state.dart';

/// Sincroniza os dados locais (offline-first) com o servidor.
///
/// Quando há internet, envia todos os registros marcados como pendentes
/// (`sincronizado == false`) para a conta do usuário logado e, em seguida,
/// marca-os como sincronizados. Sem internet, tudo continua funcionando local:
/// os registros ficam pendentes e sobem automaticamente quando a rede volta.
class SyncService {
  final SyncApi _api;
  final AuthState _auth;
  final AppState _app;

  bool _emAndamento = false;

  SyncService({required SyncApi api, required AuthState auth, required AppState app})
      : _api = api,
        _auth = auth,
        _app = app;

  bool get emAndamento => _emAndamento;

  /// Envia todos os registros pendentes do usuário logado.
  Future<void> sincronizar() async {
    if (_emAndamento) return;
    final token = _auth.token;
    if (token == null) return;
    _emAndamento = true;
    try {
      final pendentesViveiros = await _app.viveirosRepo.listarPendentes();
      final pendentesBiometrias = await _app.biometriasRepo.listarPendentes();
      final pendentesQualidade =
          await _app.qualidadeAguaRepo.listarPendentes();
      final pendentesCalculos = await _app.calculosRepo.listarPendentes();
      final pendentesSolicitacoes =
          await _app.solicitacoesRepo.listarPendentes();

      await _api.viveiros(token, pendentesViveiros);
      await _api.biometrias(token, pendentesBiometrias);
      await _api.qualidadeAgua(token, pendentesQualidade);
      await _api.calculos(token, pendentesCalculos);
      await _api.solicitacoes(token, pendentesSolicitacoes);

      // Só marca como sincronizado se os lotes foram aceitos pelo servidor.
      for (final v in pendentesViveiros) {
        await _app.viveirosRepo.salvar(v.marcadoSincronizado());
      }
      for (final b in pendentesBiometrias) {
        await _app.biometriasRepo.salvar(b.marcadoSincronizado());
      }
      for (final q in pendentesQualidade) {
        await _app.qualidadeAguaRepo.salvar(q.marcadoSincronizado());
      }
      for (final c in pendentesCalculos) {
        await _app.calculosRepo.salvar(c.marcadoSincronizado());
      }
      for (final s in pendentesSolicitacoes) {
        await _app.solicitacoesRepo.salvar(s.marcadoSincronizado());
      }

      await _app.carregar();
    } catch (e) {
      // Sem rede ou servidor indisponível: registros permanecem pendentes.
      debugPrint('SyncService: sem sincronizar agora ($e)');
    } finally {
      _emAndamento = false;
    }
  }

  /// Escuta mudanças de conectividade e dados salvos.
  ///
  /// - Sincroniza quando a internet volta (ou já está online e um novo dado foi
  ///   salvo localmente). O guard de [_emAndamento] evita sincronizações
  ///   simultâneas; sem pendentes, o método retorna imediatamente.
  void iniciarMonitor() {
    Connectivity().onConnectivityChanged.listen((resultados) {
      final online = resultados.any((r) => r != ConnectivityResult.none);
      if (online && _auth.autenticado) {
        sincronizar();
      }
    });
    _app.addListener(_quandoDadosMudam);
  }

  void _quandoDadosMudam() {
    if (_auth.autenticado && !_emAndamento) {
      sincronizar();
    }
  }
}
