import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/modelos.dart';
import '../state/app_state.dart';
import '../widgets/responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_rounded),
            SizedBox(width: 10),
            Text('AQUACENSO'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/viveiro'),
        icon: const Icon(Icons.add),
        label: const Text('Novo viveiro'),
      ),
      body: ResponsiveListView(
        children: [
          _boasVindas(context, state.viveiros.length),
          const SizedBox(height: 16),
          _cardCalculadoras(context),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seus viveiros',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (state.viveiros.isNotEmpty)
                Chip(label: Text('${state.viveiros.length} ativos')),
            ],
          ),
          const SizedBox(height: 12),
          if (state.viveiros.isEmpty)
            _vazio(context)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final colunas = constraints.maxWidth >= 760 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colunas,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 130,
                  ),
                  itemCount: state.viveiros.length,
                  itemBuilder: (context, index) =>
                      _viveiroTile(context, state, state.viveiros[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _boasVindas(BuildContext context, int totalViveiros) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cores.primary, const Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cores.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestão do cultivo, sem complicação',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: cores.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalViveiros == 0
                      ? 'Cadastre seu primeiro viveiro para acompanhar o ciclo.'
                      : 'Acompanhe biometria, alimentação e qualidade da água em um só lugar.',
                  style: TextStyle(
                    color: cores.onPrimary.withOpacity(0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.set_meal_rounded,
            size: 56,
            color: cores.onPrimary.withOpacity(0.9),
          ),
        ],
      ),
    );
  }

  Widget _cardCalculadoras(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer.withOpacity(0.55),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/calculadoras'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.calculate_rounded,
                    color: colorScheme.onPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calculadoras técnicas',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                        '12 ferramentas de carcinicultura disponíveis offline'),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vazio(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.water_outlined,
              size: 52, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text('Comece por um viveiro',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Cadastre os dados básicos para acompanhar a produção.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _viveiroTile(BuildContext context, AppState state, Viveiro v) {
    final dens = v.densidadePadrao;
    final cores = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/painel/${v.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cores.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.water_rounded,
                    color: cores.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(
                      '${_fmt(v.areaHa)} ha'
                      '${dens != null ? '  •  ${_fmt(dens)} cam/m²' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (opcao) => _acao(context, state, v, opcao),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'historico', child: Text('Histórico')),
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acao(
      BuildContext context, AppState state, Viveiro v, String opcao) async {
    switch (opcao) {
      case 'historico':
        context.push('/historico/${v.id}');
      case 'editar':
        context.push('/viveiro/${v.id}');
      case 'excluir':
        final confirma = await _confirmar(context, v.nome);
        if (confirma == true) {
          await state.removerViveiro(v.id);
        }
    }
  }

  Future<bool?> _confirmar(BuildContext context, String nome) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir viveiro?'),
        content: Text('Excluir "$nome" e todos os seus cálculos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
