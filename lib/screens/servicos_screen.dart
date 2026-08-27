import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../domain/usuario.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../state/servicos_state.dart';
import '../widgets/responsive_layout.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MercadoState>().carregarTudo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final perfil = auth.usuario?.perfil ?? PerfilUsuario.produtor;
    final isProdutor = perfil == PerfilUsuario.produtor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Serviços e Contratos'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(isProdutor ? Icons.assignment_outlined : Icons.storefront_outlined),
                text: isProdutor ? 'Minhas Solicitações' : 'Mercado / Oportunidades',
              ),
              const Tab(
                icon: Icon(Icons.handshake_outlined),
                text: 'Meus Contratos',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isProdutor ? const _MinhasSolicitacoesTab() : const _MercadoAbertosTab(),
            const _MeusContratosTab(),
          ],
        ),
        floatingActionButton: isProdutor
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/servicos/novo'),
                icon: const Icon(Icons.add),
                label: const Text('Nova Solicitação'),
              )
            : null,
      ),
    );
  }
}

/// Aba do produtor com suas solicitações criadas.
class _MinhasSolicitacoesTab extends StatelessWidget {
  const _MinhasSolicitacoesTab();

  @override
  Widget build(BuildContext context) {
    final mercado = context.watch<MercadoState>();
    final app = context.watch<AppState>();

    // Combina solicitações online com rascunhos offline locais
    final online = mercado.meusServicos;
    final idsOnline = online.map((s) => s.id).toSet();
    final locaisApenas = app.solicitacoes.where((s) => !idsOnline.contains(s.id)).toList();
    final lista = [...locaisApenas, ...online];

    return RefreshIndicator(
      onRefresh: () async {
        final m = context.read<MercadoState>();
        final a = context.read<AppState>();
        await m.carregarMeusServicos();
        await a.carregar();
      },
      child: lista.isEmpty
          ? ResponsiveListView(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.assignment_late_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Você ainda não criou solicitações',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Toque em "Nova Solicitação" para contratar técnicos qualificados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : ResponsiveListView(
              children: [
                const SizedBox(height: 12),
                for (final item in lista) ...[
                  _CardMinhaSolicitacao(item: item),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _CardMinhaSolicitacao extends StatelessWidget {
  final SolicitacaoServico item;
  const _CardMinhaSolicitacao({required this.item});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final statusColor = item.status == 'aberto'
        ? Colors.orange
        : item.status == 'aceito'
            ? cores.primary
            : Colors.grey;
    final statusText = item.status == 'aberto'
        ? 'Aberto / Propostas'
        : item.status == 'aceito'
            ? 'Aceito / Em Contrato'
            : 'Cancelado';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/servicos/meu/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (item.categoria != null || item.cidade != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (item.categoria != null)
                      Chip(
                        label: Text(item.categoria!, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    if (item.cidade != null)
                      Chip(
                        avatar: const Icon(Icons.location_on_outlined, size: 14),
                        label: Text(item.cidade!, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Valor Estimado:',
                    style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
                  ),
                  Text(
                    'R\$ ${item.valorEstimado.toStringAsFixed(2)}',
                    style: TextStyle(color: cores.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              if (!item.sincronizado) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 14, color: cores.error),
                    const SizedBox(width: 4),
                    Text(
                      'Pendente de sincronização offline',
                      style: TextStyle(fontSize: 11, color: cores.error),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Aba do técnico com lista de serviços abertos para propor.
class _MercadoAbertosTab extends StatelessWidget {
  const _MercadoAbertosTab();

  @override
  Widget build(BuildContext context) {
    final mercado = context.watch<MercadoState>();
    final lista = mercado.abertos;

    return RefreshIndicator(
      onRefresh: () => context.read<MercadoState>().carregarAbertos(),
      child: lista.isEmpty
          ? ResponsiveListView(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.work_outline_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Nenhuma oportunidade aberta no momento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Puxe para baixo para atualizar e conferir novas solicitações de produtores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : ResponsiveListView(
              children: [
                const SizedBox(height: 12),
                for (final item in lista) ...[
                  _CardOportunidade(item: item),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _CardOportunidade extends StatelessWidget {
  final SolicitacaoServico item;
  const _CardOportunidade({required this.item});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/servicos/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cores.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aberto',
                      style: TextStyle(
                        color: cores.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.produtorNome.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Solicitante: ${item.produtorNome}',
                  style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                ),
              ],
              if (item.categoria != null || item.cidade != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (item.categoria != null)
                      Chip(
                        label: Text(item.categoria!, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    if (item.cidade != null)
                      Chip(
                        avatar: const Icon(Icons.location_on_outlined, size: 14),
                        label: Text(item.cidade!, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Valor Estimado:',
                    style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
                  ),
                  Text(
                    'R\$ ${item.valorEstimado.toStringAsFixed(2)}',
                    style: TextStyle(color: cores.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aba compartilhada de contratos ativos e concluídos.
class _MeusContratosTab extends StatelessWidget {
  const _MeusContratosTab();

  @override
  Widget build(BuildContext context) {
    final mercado = context.watch<MercadoState>();
    final lista = mercado.meusContratos;

    return RefreshIndicator(
      onRefresh: () => context.read<MercadoState>().carregarMeusContratos(),
      child: lista.isEmpty
          ? ResponsiveListView(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.handshake_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Nenhum contrato ativo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Quando uma proposta for aceita, o contrato aparecerá aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : ResponsiveListView(
              children: [
                const SizedBox(height: 12),
                for (final item in lista) ...[
                  _CardContrato(item: item),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _CardContrato extends StatelessWidget {
  final ContratoServico item;
  const _CardContrato({required this.item});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    Color statusColor;
    String statusLabel;

    switch (item.execucao) {
      case 'aguardando_pagamento':
        statusColor = Colors.orange;
        statusLabel = 'Aguardando Pagamento';
        break;
      case 'em_andamento':
        statusColor = Colors.blue;
        statusLabel = 'Em Andamento';
        break;
      case 'aguardando_aprovacao':
        statusColor = Colors.purple;
        statusLabel = 'Aguardando Aprovação';
        break;
      case 'concluido':
        statusColor = cores.primary;
        statusLabel = 'Concluído';
        break;
      case 'cancelado':
      default:
        statusColor = cores.error;
        statusLabel = 'Cancelado / Restituído';
        break;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/contrato/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.servicoTitulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: cores.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Produtor: ${item.produtorNome} • Técnico: ${item.tecnicoNome}',
                      style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.comunicacaoLiberada ? Icons.chat_rounded : Icons.chat_outlined,
                        size: 16,
                        color: item.comunicacaoLiberada ? cores.primary : cores.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.comunicacaoLiberada ? 'Chat liberado' : 'Chat bloqueado',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.comunicacaoLiberada ? cores.primary : cores.outline,
                          fontWeight: item.comunicacaoLiberada ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'R\$ ${item.valorAcordado.toStringAsFixed(2)}',
                    style: TextStyle(color: cores.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
