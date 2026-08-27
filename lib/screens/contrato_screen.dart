import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../state/auth_state.dart';
import '../state/servicos_state.dart';
import '../widgets/responsive_layout.dart';

// Imagens demonstrativas codificadas em Base64 PNG para fins de demonstração imediata
const _kDemoFotoVisita =
    'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="260" viewBox="0 0 400 260"><rect width="400" height="260" fill="%231e293b"/><rect x="20" y="20" width="360" height="220" rx="12" fill="%23334155"/><circle cx="200" cy="110" r="45" fill="%23ef4444" opacity="0.2"/><path d="M185 95 L215 125 M215 95 L185 125" stroke="%23ef4444" stroke-width="6" stroke-linecap="round"/><text x="200" y="175" fill="%23f8fafc" font-size="15" font-weight="bold" font-family="sans-serif" text-anchor="middle">VISITA TÉCNICA: FALHA DETECTADA</text><text x="200" y="198" fill="%2394a3b8" font-size="12" font-family="sans-serif" text-anchor="middle">Inspeção no sistema de bombeamento do viveiro 02</text><rect x="30" y="30" width="100" height="24" rx="6" fill="%23ef4444"/><text x="80" y="46" fill="white" font-size="11" font-weight="bold" font-family="sans-serif" text-anchor="middle">ANTES / VISITA</text></svg>';

const _kDemoFotoSolucao =
    'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="260" viewBox="0 0 400 260"><rect width="400" height="260" fill="%23064e3b"/><rect x="20" y="20" width="360" height="220" rx="12" fill="%23065f46"/><circle cx="200" cy="110" r="45" fill="%2310b981" opacity="0.2"/><path d="M180 110 L195 125 L225 95" stroke="%2310b981" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><text x="200" y="175" fill="%23f8fafc" font-size="15" font-weight="bold" font-family="sans-serif" text-anchor="middle">SOLUÇÃO APLICADA: TESTE OK</text><text x="200" y="198" fill="%236ee7b7" font-size="12" font-family="sans-serif" text-anchor="middle">Rotor substituído, vazão 120m³/h restabelecida</text><rect x="30" y="30" width="110" height="24" rx="6" fill="%2310b981"/><text x="85" y="46" fill="white" font-size="11" font-weight="bold" font-family="sans-serif" text-anchor="middle">DEPOIS / SOLUÇÃO</text></svg>';

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

  /// Abre diálogo para o técnico anexar fotos de comprovação da visita e solução.
  Future<void> _abrirDialogFinalizacao(ContratoServico contrato) async {
    String? fotoVisita = contrato.fotoVisita;
    String? fotoSolucao = contrato.fotoSolucao;
    final descCtrl = TextEditingController(text: contrato.descricaoSolucao ?? '');

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cores = Theme.of(context).colorScheme;
          final picker = ImagePicker();

          Future<void> escolherFoto(bool isVisita, ImageSource source) async {
            try {
              final picked = await picker.pickImage(
                source: source,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                setDialogState(() {
                  if (isVisita) {
                    fotoVisita = base64String;
                  } else {
                    fotoSolucao = base64String;
                  }
                });
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao selecionar imagem: $e')),
                );
              }
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.camera_alt_outlined),
                SizedBox(width: 10),
                Expanded(child: Text('Comprovante de Execução')),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anexe fotos comprovando a visita técnica e a solução do problema para avaliação e aprovação do produtor.',
                      style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    // Campo 1: Foto da Visita / Diagnóstico (Antes)
                    const Text(
                      '1. Foto da Visita Técnica / Problema (Antes)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (fotoVisita != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _RenderImagem(
                              uriString: fotoVisita!,
                              height: 140,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton.filled(
                              icon: const Icon(Icons.close, size: 16),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => setDialogState(() => fotoVisita = null),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => escolherFoto(true, ImageSource.camera),
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('Câmera / Galeria'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => setDialogState(() => fotoVisita = _kDemoFotoVisita),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('Usar Foto Demo (Visita)'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Campo 2: Foto da Solução / Conclusão (Depois)
                    const Text(
                      '2. Foto da Solução do Problema (Depois)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (fotoSolucao != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _RenderImagem(
                              uriString: fotoSolucao!,
                              height: 140,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton.filled(
                              icon: const Icon(Icons.close, size: 16),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => setDialogState(() => fotoSolucao = null),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => escolherFoto(false, ImageSource.camera),
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('Câmera / Galeria'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => setDialogState(() => fotoSolucao = _kDemoFotoSolucao),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('Usar Foto Demo (Solução)'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Campo 3: Descrição técnica
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Relatório do Serviço / Observações Técnicas',
                        hintText: 'Ex.: Realizada a troca do rotor e ajuste de vazão...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.check),
                label: const Text('Finalizar e Enviar Comprovante'),
              ),
            ],
          );
        },
      ),
    );

    if (resultado != true || !mounted) return;

    setState(() => _processando = true);
    try {
      final mercado = context.read<MercadoState>();
      final desc = descCtrl.text.trim();
      await mercado.finalizarServico(
        contrato.id,
        fotoVisita: fotoVisita,
        fotoSolucao: fotoSolucao,
        descricaoSolucao: desc.isEmpty ? null : desc,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço finalizado com comprovante anexado! Aguardando aprovação do produtor.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar: $e'),
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

    final temComprovante = c.fotoVisita != null || c.fotoSolucao != null || c.descricaoSolucao != null;

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

            // Card de Relatório Fotográfico & Comprovante de Visita / Solução
            if (temComprovante || c.execucao == 'aguardando_aprovacao' || c.execucao == 'concluido') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_library_outlined, color: cores.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Relatório Fotográfico & Comprovação',
                              style: TextStyle(fontWeight: FontWeight.bold, color: cores.primary, fontSize: 15),
                            ),
                          ),
                          if (c.execucao == 'aguardando_aprovacao')
                            Chip(
                              label: const Text('Para Aprovação'),
                              backgroundColor: Colors.purple.withOpacity(0.15),
                              labelStyle: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isProdutor && c.execucao == 'aguardando_aprovacao')
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cores.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: cores.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Avalie as fotos da visita e da solução abaixo antes de aprovar a liberação do pagamento.',
                                  style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Grid ou Colunas das Fotos
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 500;
                          return Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Foto 1: Visita / Antes
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📸 1. Visita Técnica (Antes)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cores.onSurface),
                                    ),
                                    const SizedBox(height: 6),
                                    if (c.fotoVisita != null)
                                      InkWell(
                                        onTap: () => _abrirZoomImagem(context, 'Visita Técnica (Antes)', c.fotoVisita!),
                                        borderRadius: BorderRadius.circular(8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: _RenderImagem(uriString: c.fotoVisita!, height: 160, width: double.infinity),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: cores.surfaceVariant.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text('Nenhuma foto anexada', style: TextStyle(fontSize: 12, color: cores.outline)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                              // Foto 2: Solução / Depois
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '✅ 2. Solução Concluída (Depois)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cores.onSurface),
                                    ),
                                    const SizedBox(height: 6),
                                    if (c.fotoSolucao != null)
                                      InkWell(
                                        onTap: () => _abrirZoomImagem(context, 'Solução Concluída (Depois)', c.fotoSolucao!),
                                        borderRadius: BorderRadius.circular(8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: _RenderImagem(uriString: c.fotoSolucao!, height: 160, width: double.infinity),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: cores.surfaceVariant.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text('Nenhuma foto anexada', style: TextStyle(fontSize: 12, color: cores.outline)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      if (c.descricaoSolucao != null && c.descricaoSolucao!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Observações Técnicas do Executor:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cores.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cores.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c.descricaoSolucao!,
                            style: TextStyle(fontSize: 13, color: cores.onSurface),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

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

              // 2. Técnico finaliza (se em andamento) -> abre diálogo de anexar fotos e relatório
              if (isTecnico && c.execucao == 'em_andamento')
                FilledButton.icon(
                  onPressed: () => _abrirDialogFinalizacao(c),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Finalizar Serviço e Inserir Comprovante'),
                ),

              // 3. Produtor aprova ou rejeita (se aguardando aprovação)
              if (isProdutor && c.execucao == 'aguardando_aprovacao') ...[
                FilledButton.icon(
                  onPressed: () => _executarAcao(
                    'Aprovar Serviço e Repassar Pagamento',
                    'Você confirma que avaliou o relatório fotográfico e que o serviço foi concluído com sucesso?\n\n'
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

  void _abrirZoomImagem(BuildContext context, String titulo, String uriString) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: _RenderImagem(uriString: uriString, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget auxiliar para renderizar imagens de Data URI (Base64/SVG) ou URLs HTTP.
class _RenderImagem extends StatelessWidget {
  final String uriString;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _RenderImagem({
    required this.uriString,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (uriString.startsWith('data:image/svg+xml')) {
      final svgRaw = Uri.decodeComponent(uriString.split(',').last);
      return Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        color: const Color(0xFF0F172A),
        child: _SvgViewer(svgContent: svgRaw, height: height, width: width),
      );
    } else if (uriString.startsWith('data:image')) {
      try {
        final base64String = uriString.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, height: height, width: width, fit: fit);
      } catch (_) {
        return Container(
          height: height,
          width: width,
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.white),
        );
      }
    } else if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      return Image.network(
        uriString,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: width,
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.white),
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      color: Colors.grey[800],
      child: const Icon(Icons.image_not_supported, color: Colors.white),
    );
  }
}

class _SvgViewer extends StatelessWidget {
  final String svgContent;
  final double? height;
  final double? width;

  const _SvgViewer({
    required this.svgContent,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isVisita = svgContent.contains('VISITA TÉCNICA');

    return Container(
      height: height ?? 160,
      width: width ?? double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVisita ? const Color(0xFF1E293B) : const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVisita ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 44,
            color: isVisita ? Colors.redAccent : Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          Text(
            isVisita ? 'FALHA DETECTADA NA VISITA' : 'SOLUÇÃO CONCLUÍDA E TESTADA',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isVisita
                ? 'Inspeção no sistema de bombeamento do viveiro'
                : 'Rotor reparado e vazão nominal restabelecida',
            style: TextStyle(
              color: isVisita ? Colors.white70 : Colors.greenAccent.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
