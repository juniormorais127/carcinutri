import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../state/auth_state.dart';
import '../state/servicos_state.dart';

class ChatScreen extends StatefulWidget {
  final String contratoId;
  const ChatScreen({super.key, required this.contratoId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textoController = TextEditingController();
  final _scrollController = ScrollController();

  List<MensagemServico> _mensagens = [];
  bool _carregando = true;
  bool _enviando = false;
  String? _erro;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarMensagens();
    // Atualiza mensagens a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _carregarMensagens(silencioso: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarMensagens({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final mercado = context.read<MercadoState>();
      final msgs = await mercado.listarMensagens(widget.contratoId);
      if (mounted) {
        final mudou = msgs.length != _mensagens.length;
        setState(() {
          _mensagens = msgs;
          _erro = null;
        });
        if (mudou) {
          _scrollParaFinal();
        }
      }
    } catch (e) {
      if (mounted && !silencioso) {
        setState(() => _erro = e.toString());
      }
    } finally {
      if (mounted && !silencioso) {
        setState(() => _carregando = false);
      }
    }
  }

  void _scrollParaFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty || _enviando) return;

    _textoController.clear();
    setState(() => _enviando = true);

    try {
      final mercado = context.read<MercadoState>();
      final msg = await mercado.enviarMensagem(widget.contratoId, texto);
      if (mounted) {
        setState(() {
          _mensagens.add(msg);
        });
        _scrollParaFinal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final auth = context.watch<AuthState>();
    final userId = auth.usuario?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat do Serviço'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _carregarMensagens(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cores.primaryContainer.withOpacity(0.25),
            child: Row(
              children: [
                Icon(Icons.lock_open_rounded, size: 16, color: cores.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat seguro protegido por custódia.',
                    style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 40, color: cores.error),
                              const SizedBox(height: 8),
                              Text(_erro!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => _carregarMensagens(),
                                child: const Text('Tentar Novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _mensagens.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: cores.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma mensagem ainda',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: cores.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Inicie a conversa enviando uma mensagem abaixo.',
                                  style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: _mensagens.length,
                            itemBuilder: (context, index) {
                              final msg = _mensagens[index];
                              final isMe = msg.remetenteId == userId;
                              return _BolhaMensagem(msg: msg, isMe: isMe);
                            },
                          ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cores.surface,
                border: Border(top: BorderSide(color: cores.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BolhaMensagem extends StatelessWidget {
  final MensagemServico msg;
  final bool isMe;

  const _BolhaMensagem({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final hora = '${msg.criadoEm.hour.toString().padLeft(2, '0')}:${msg.criadoEm.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? cores.primary : cores.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && msg.remetenteNome.isNotEmpty) ...[
              Text(
                msg.remetenteNome,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cores.primary,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.texto,
              style: TextStyle(
                color: isMe ? cores.onPrimary : cores.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hora,
              style: TextStyle(
                fontSize: 10,
                color: (isMe ? cores.onPrimary : cores.onSurfaceVariant).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
