import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../state/servicos_state.dart';
import '../widgets/responsive_layout.dart';

class MeuServicoScreen extends StatefulWidget {
  final String id;
  const MeuServicoScreen({super.key, required this.id});

  @override
  State<MeuServicoScreen> createState() => _MeuServicoScreenState();
}

class _MeuServicoScreenState extends State<MeuServicoScreen> {
  SolicitacaoServico? _servico;
  List<PropostaServico> _propostas = [];
  bool _carregando = true;
  bool _aceitando = false;
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
      final s = await mercado.obterServico(widget.id);
      final p = await mercado.listarPropostas(widget.id);
      if (mounted) {
        setState(() {
          _servico = s;
          _propostas = p;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _confirmarAceite(PropostaServico proposta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceitar Proposta?'),
        content: Text(
          'Deseja aceitar a proposta de ${proposta.tecnicoNome} no valor de R\$ ${proposta.valor.toStringAsFixed(2)}?\n\n'
          'Ao aceitar, o contrato será criado e o serviço entrará em etapa de custódia (pagamento em garantia).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar e Gerar Contrato'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _aceitando = true);
    try {
      final mercado = context.read<MercadoState>();
      final contrato = await mercado.aceitarProposta(widget.id, proposta.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposta aceita com sucesso! Contrato gerado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pushReplacement('/contrato/${contrato.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar proposta: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aceitando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Minha Solicitação')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null || _servico == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Minha Solicitação')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cores.error),
                const SizedBox(height: 12),
                Text(_erro ?? 'Solicitação não encontrada.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _carregar, child: const Text('Tentar Novamente')),
              ],
            ),
          ),
        ),
      );
    }

    final s = _servico!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Solicitação'),
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
                            s.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.status == 'aberto' ? Colors.orange.withOpacity(0.15) : cores.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.status == 'aberto' ? 'Aberto para propostas' : 'Aceito',
                            style: TextStyle(
                              color: s.status == 'aberto' ? Colors.orange[800] : cores.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (s.categoria != null || s.cidade != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (s.categoria != null)
                            Chip(label: Text(s.categoria!), visualDensity: VisualDensity.compact),
                          if (s.cidade != null)
                            Chip(
                              avatar: const Icon(Icons.location_on_outlined, size: 16),
                              label: Text(s.cidade!),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valor Estimado Inicial:', style: TextStyle(color: cores.onSurfaceVariant)),
                        Text(
                          'R\$ ${s.valorEstimado.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: cores.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    if (s.descricao != null && s.descricao!.isNotEmpty) ...[
                      const Divider(height: 28),
                      Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold, color: cores.onSurface)),
                      const SizedBox(height: 6),
                      Text(s.descricao!, style: TextStyle(color: cores.onSurfaceVariant, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Propostas Recebidas (${_propostas.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_aceitando) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            if (_propostas.isEmpty)
              Card(
                color: cores.surfaceVariant.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 40, color: cores.outline),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhuma proposta recebida ainda',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assim que técnicos enviarem propostas, elas aparecerão aqui para sua avaliação.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final p in _propostas) ...[
                _CardPropostaItem(
                  proposta: p,
                  solicitacaoAberta: s.status == 'aberto',
                  onAceitar: _aceitando ? null : () => _confirmarAceite(p),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CardPropostaItem extends StatelessWidget {
  final PropostaServico proposta;
  final bool solicitacaoAberta;
  final VoidCallback? onAceitar;

  const _CardPropostaItem({
    required this.proposta,
    required this.solicitacaoAberta,
    required this.onAceitar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final isPendente = proposta.status == 'pendente';
    final isAceita = proposta.status == 'aceita';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cores.primaryContainer,
                  child: Icon(Icons.person, color: cores.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposta.tecnicoNome,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Técnico Credenciado',
                        style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${proposta.valor.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: cores.primary,
                  ),
                ),
              ],
            ),
            if (proposta.mensagem != null && proposta.mensagem!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cores.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  proposta.mensagem!,
                  style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAceita
                        ? cores.primaryContainer
                        : isPendente
                            ? Colors.orange.withOpacity(0.15)
                            : cores.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAceita
                        ? 'Proposta Aceita'
                        : isPendente
                            ? 'Pendente de Resposta'
                            : 'Recusada',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAceita
                          ? cores.onPrimaryContainer
                          : isPendente
                              ? Colors.orange[800]
                              : cores.error,
                    ),
                  ),
                ),
                if (solicitacaoAberta && isPendente)
                  FilledButton.icon(
                    onPressed: onAceitar,
                    icon: const Icon(Icons.handshake_rounded, size: 18),
                    label: const Text('Aceitar Proposta'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
