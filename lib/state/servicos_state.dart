import 'package:flutter/foundation.dart';

import '../data/servicos_api.dart';
import '../domain/servico.dart';
import 'auth_state.dart';

/// Estado de gerenciamento do Marketplace de Serviços, Contratos e Chat.
class MercadoState extends ChangeNotifier {
  final ServicosApi _api;
  final AuthState _auth;

  MercadoState({required ServicosApi api, required AuthState auth})
      : _api = api,
        _auth = auth;

  List<SolicitacaoServico> _abertos = [];
  List<SolicitacaoServico> _meusServicos = [];
  List<ContratoServico> _meusContratos = [];
  bool _carregando = false;
  String? _erro;

  List<SolicitacaoServico> get abertos => List.unmodifiable(_abertos);
  List<SolicitacaoServico> get meusServicos => List.unmodifiable(_meusServicos);
  List<ContratoServico> get meusContratos => List.unmodifiable(_meusContratos);
  bool get carregando => _carregando;
  String? get erro => _erro;

  String? get _token => _auth.token;

  Future<void> carregarTudo() async {
    if (_token == null) return;
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      await Future.wait([
        carregarAbertos(silencioso: true),
        carregarMeusServicos(silencioso: true),
        carregarMeusContratos(silencioso: true),
      ]);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> carregarAbertos({
    String? categoria,
    String? cidade,
    bool silencioso = false,
  }) async {
    final token = _token;
    if (token == null) return;
    if (!silencioso) {
      _carregando = true;
      _erro = null;
      notifyListeners();
    }
    try {
      _abertos = await _api.listarAbertos(token, categoria: categoria, cidade: cidade);
    } catch (e) {
      _erro = e.toString();
    } finally {
      if (!silencioso) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  Future<void> carregarMeusServicos({bool silencioso = false}) async {
    final token = _token;
    if (token == null) return;
    if (!silencioso) {
      _carregando = true;
      _erro = null;
      notifyListeners();
    }
    try {
      _meusServicos = await _api.meusServicos(token);
    } catch (e) {
      _erro = e.toString();
    } finally {
      if (!silencioso) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  Future<void> carregarMeusContratos({bool silencioso = false}) async {
    final token = _token;
    if (token == null) return;
    if (!silencioso) {
      _carregando = true;
      _erro = null;
      notifyListeners();
    }
    try {
      _meusContratos = await _api.meusContratos(token);
    } catch (e) {
      _erro = e.toString();
    } finally {
      if (!silencioso) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  Future<SolicitacaoServico> criarSolicitacao({
    required String titulo,
    String? descricao,
    String? categoria,
    String? cidade,
    required double valorEstimado,
  }) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final s = await _api.criarSolicitacao(
      token,
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      cidade: cidade,
      valorEstimado: valorEstimado,
    );
    await carregarTudo();
    return s;
  }

  Future<SolicitacaoServico> obterServico(String servicoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    return await _api.obterServico(token, servicoId);
  }

  Future<List<PropostaServico>> listarPropostas(String servicoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    return await _api.listarPropostas(token, servicoId);
  }

  Future<PropostaServico> criarProposta(
    String servicoId, {
    required double valor,
    String? mensagem,
  }) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final p = await _api.criarProposta(token, servicoId, valor: valor, mensagem: mensagem);
    notifyListeners();
    return p;
  }

  Future<ContratoServico> aceitarProposta(
    String servicoId,
    String propostaId,
  ) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final c = await _api.aceitarProposta(token, servicoId, propostaId);
    await carregarTudo();
    return c;
  }

  Future<ContratoServico> obterContrato(String contratoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    return await _api.obterContrato(token, contratoId);
  }

  Future<ContratoServico> pagarContrato(String contratoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final c = await _api.pagarContrato(token, contratoId);
    await carregarMeusContratos(silencioso: true);
    notifyListeners();
    return c;
  }

  Future<ContratoServico> finalizarServico(
    String contratoId, {
    String? fotoVisita,
    String? fotoSolucao,
    String? descricaoSolucao,
  }) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final c = await _api.finalizarServico(
      token,
      contratoId,
      fotoVisita: fotoVisita,
      fotoSolucao: fotoSolucao,
      descricaoSolucao: descricaoSolucao,
    );
    await carregarMeusContratos(silencioso: true);
    notifyListeners();
    return c;
  }

  Future<ContratoServico> aprovarServico(String contratoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final c = await _api.aprovarServico(token, contratoId);
    await carregarMeusContratos(silencioso: true);
    notifyListeners();
    return c;
  }

  Future<ContratoServico> rejeitarServico(String contratoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    final c = await _api.rejeitarServico(token, contratoId);
    await carregarMeusContratos(silencioso: true);
    notifyListeners();
    return c;
  }

  Future<List<MensagemServico>> listarMensagens(String contratoId) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    return await _api.listarMensagens(token, contratoId);
  }

  Future<MensagemServico> enviarMensagem(String contratoId, String texto) async {
    final token = _token;
    if (token == null) throw Exception('Não autenticado');
    return await _api.enviarMensagem(token, contratoId, texto);
  }
}
