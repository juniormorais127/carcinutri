import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../state/auth_state.dart';
import '../state/servicos_state.dart';
import '../widgets/responsive_layout.dart';

class ContratoScreen extends StatefulWidget {
  final String id;
  const ContratoScreen({super.key, required this.id});

  @override
  State<ContratoScreen> createState() => _ContratoScreenState();
}

class _ContratoScreenState extends State<ContratoScreen> {
  ContratoServico? _contrato;
  bool _carregando = true;
  bool _processando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final mercado = context.read<MercadoState>();
      final c = await mercado.obterContrato(widget.id);
      if (mounted) setState(() => _contrato = c);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _executarAcao(
    String titulo,
    String mensagem,
    Future<void> Function(MercadoState) acao,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _processando = true);
    try {
      final mercado = context.read<MercadoState>();
      await acao(mercado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operação realizada com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final auth = context.watch<AuthState>();
    final userId = auth.usuario?.id;

    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contrato de Serviço')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null || _contrato == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contrato de Serviço')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cores.error),
                const SizedBox(height: 12),
                Text(_erro ?? 'Contrato não encontrado.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _carregar, child: const Text('Tentar Novamente')),
              ],
            ),
          ),
        ),
      );
    }

    final c = _contrato!;
    final isProdutor = userId == c.produtorId;
    final isTecnico = userId == c.tecnicoId;

    Color statusColor;
    String statusLabel;
    switch (c.execucao) {
      case 'aguardando_pagamento':
        statusColor = Colors.orange;
        statusLabel = 'Aguardando Pagamento em Custódia';
        break;
      case 'em_andamento':
        statusColor = Colors.blue;
        statusLabel = 'Em Execução';
        break;
      case 'aguardando_aprovacao':
        statusColor = Colors.purple;
        statusLabel = 'Aguardando Aprovação do Produtor';
        break;
      case 'concluido':
        statusColor = cores.primary;
        statusLabel = 'Concluído e Repassado';
        break;
      case 'cancelado':
      default:
        statusColor = cores.error;
        statusLabel = 'Cancelado e Restituído';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato de Serviço'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ResponsiveListView(
          children: [
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.servicoTitulo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valor Acordado:', style: TextStyle(color: cores.onSurfaceVariant)),
                        Text(
                          'R\$ ${c.valorAcordado.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: cores.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Produtor (Contratante)', style: TextStyle(fontSize: 11, color: cores.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(c.produtorNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Técnico (Executor)', style: TextStyle(fontSize: 11, color: cores.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(c.tecnicoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card de Custódia (Escrow)
            Card(
              color: cores.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: cores.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Garantia de Pagamento (Custódia)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: cores.primary, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.pagamento == 'aguardando'
                          ? 'O pagamento ainda não foi depositado em custódia. O serviço não deve ser iniciado até o depósito.'
                          : c.pagamento == 'pago'
                              ? '✓ Valor de R\$ ${c.valorAcordado.toStringAsFixed(2)} retido em custódia com segurança. O técnico já pode executar o serviço.'
                              : c.pagamento == 'repassado'
                                  ? '✓ Pagamento repassado com sucesso ao técnico após aprovação do serviço.'
                                  : '✗ Pagamento restituído ao produtor.',
                      style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card de Chat / Comunicação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          c.comunicacaoLiberada ? Icons.chat_rounded : Icons.lock_outline,
                          color: c.comunicacaoLiberada ? cores.primary : cores.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Canal de Comunicação Direta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.comunicacaoLiberada ? cores.primary : cores.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.comunicacaoLiberada
                          ? 'Comunicação liberada! Use o chat integrado para alinhar detalhes, horários e fotos do serviço.'
                          : 'O chat será liberado automaticamente assim que o produtor confirmar o pagamento em custódia.',
                      style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                    ),
                    if (c.comunicacaoLiberada) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/chat/${c.id}'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: Text('Abrir Chat com ${isProdutor ? c.tecnicoNome : c.produtorNome}'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ações do Contrato conforme o Perfil e Estado
            if (_processando)
              const Center(child: CircularProgressIndicator())
            else ...[
              // 1. Produtor paga (se aguardando pagamento)
              if (isProdutor && c.pagamento == 'aguardando')
                FilledButton.icon(
                  onPressed: () => _executarAcao(
                    'Confirmar Pagamento em Custódia',
                    'Simulação de pagamento no valor de R\$ ${c.valorAcordado.toStringAsFixed(2)}.\n\n'
                    'O valor ficará retido com segurança em garantia e o técnico será autorizado a iniciar o trabalho. O chat será liberado imediatamente.',
                    (m) => m.pagarContrato(c.id),
                  ),
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('Realizar Pagamento em Custódia (Simulado)'),
                ),

              // 2. Técnico finaliza (se em andamento)
              if (isTecnico && c.execucao == 'em_andamento')
                FilledButton.icon(
                  onPressed: () => _executarAcao(
                    'Finalizar Execução do Serviço',
                    'Você confirma que finalizou a execução deste serviço?\n\n'
                    'O produtor será notificado para conferir e aprovar o repasse do pagamento.',
                    (m) => m.finalizarServico(c.id),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar Serviço como Finalizado'),
                ),

              // 3. Produtor aprova ou rejeita (se aguardando aprovação)
              if (isProdutor && c.execucao == 'aguardando_aprovacao') ...[
                FilledButton.icon(
                  onPressed: () => _executarAcao(
                    'Aprovar Serviço e Repassar Pagamento',
                    'Você confirma que o serviço foi concluído satisfatoriamente?\n\n'
                    'O valor de R\$ ${c.valorAcordado.toStringAsFixed(2)} será repassado ao técnico ${c.tecnicoNome}.',
                    (m) => m.aprovarServico(c.id),
                  ),
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: const Text('Aprovar e Liberar Pagamento ao Técnico'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _executarAcao(
                    'Rejeitar Serviço e Solicitar Restituição',
                    'Deseja rejeitar o serviço?\n\n'
                    'O contrato será cancelado e o valor em custódia será restituído à sua conta.',
                    (m) => m.rejeitarServico(c.id),
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: cores.error),
                  icon: const Icon(Icons.thumb_down_alt_outlined),
                  label: const Text('Rejeitar e Restituir Valor'),
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
