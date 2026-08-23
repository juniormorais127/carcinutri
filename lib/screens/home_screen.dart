import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/modelos.dart';
import '../domain/painel.dart';
import '../state/app_state.dart';
import '../widgets/responsive_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pesoAlvo = TextEditingController(text: '20');
  final _precoKg = TextEditingController(text: '30');

  @override
  void dispose() {
    _pesoAlvo.dispose();
    _precoKg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final resumos = [
      for (final viveiro in state.viveiros)
        resumirViveiro(
          viveiro,
          state.listarBiometrias(viveiro.id),
          state.listarQualidadeAgua(viveiro.id),
        ),
    ];
    final geral = resumirGeral(resumos);
    final pesoAlvo = _numero(_pesoAlvo, 20);
    final precoKg = _numero(_precoKg, 30);

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
          _cardResumo(context, geral),
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
                    mainAxisExtent: 188,
                  ),
                  itemCount: state.viveiros.length,
                  itemBuilder: (context, index) => _viveiroTile(
                    context,
                    state,
                    state.viveiros[index],
                    resumos[index],
                  ),
                );
              },
            ),
          if (state.viveiros.isNotEmpty) ...[
            const SizedBox(height: 28),
            _secaoDespesca(
              context,
              state,
              resumos,
              pesoAlvo: pesoAlvo,
              precoKg: precoKg,
            ),
          ],
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
          colors: [
            cores.primary,
            Color.lerp(cores.primary, cores.onPrimary, 0.12)!,
          ],
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
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cores.onPrimary.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cores.onPrimary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt_rounded, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'SISTEMA OFFLINE ATIVO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
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

  Widget _cardResumo(BuildContext context, ResumoGeral resumo) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cores.tertiaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.monitor_heart_outlined,
                      color: cores.onTertiaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo da produção',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        'Visão consolidada dos viveiros',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: cores.primaryContainer.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ATUALIZADO',
                    style: TextStyle(
                      color: cores.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final colunas = constraints.maxWidth >= 820
                    ? 5
                    : constraints.maxWidth >= 520
                        ? 3
                        : 2;
                final largura =
                    (constraints.maxWidth - (colunas - 1) * 10) / colunas;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _metricaResumo(
                      context,
                      largura,
                      icon: Icons.water_rounded,
                      rotulo: 'Viveiros',
                      valor: '${resumo.nViveiros}',
                    ),
                    _metricaResumo(
                      context,
                      largura,
                      icon: Icons.square_foot_rounded,
                      rotulo: 'Área total',
                      valor: '${_fmt(resumo.areaTotalHa)} ha',
                    ),
                    _metricaResumo(
                      context,
                      largura,
                      icon: Icons.scale_outlined,
                      rotulo: 'Biomassa',
                      valor: _valorOuTraco(resumo.biomassaTotalKg, 'kg'),
                    ),
                    _metricaResumo(
                      context,
                      largura,
                      icon: Icons.restaurant_rounded,
                      rotulo: 'Ração hoje',
                      valor: _valorOuTraco(resumo.racaoTotalDiaKg, 'kg'),
                    ),
                    _metricaResumo(
                      context,
                      largura,
                      icon: resumo.nAlertas == 0
                          ? Icons.verified_outlined
                          : Icons.warning_amber_rounded,
                      rotulo: 'Alertas',
                      valor: '${resumo.nAlertas}',
                      alerta: resumo.nAlertas > 0,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricaResumo(
    BuildContext context,
    double largura, {
    required IconData icon,
    required String rotulo,
    required String valor,
    bool alerta = false,
  }) {
    final cores = Theme.of(context).colorScheme;
    final cor = alerta ? cores.error : cores.primary;
    return Container(
      width: largura,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withOpacity(0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cor),
          const SizedBox(height: 8),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall),
        ],
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

  Widget _viveiroTile(
    BuildContext context,
    AppState state,
    Viveiro v,
    ResumoViveiro resumo,
  ) {
    final dens = v.densidadePadrao;
    final cores = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/painel/${v.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            children: [
              Row(
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(v.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ),
                            if (resumo.alertasAgua.isNotEmpty)
                              Icon(Icons.warning_amber_rounded,
                                  size: 18, color: cores.error),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_fmt(v.areaHa)} ha'
                          '${dens != null ? '  •  ${_fmt(dens)} cam/m²' : ''}'
                          '${resumo.idadeDias != null ? '  •  ${resumo.idadeDias} dias' : ''}',
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
                      PopupMenuItem(
                          value: 'historico', child: Text('Histórico')),
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: cores.outlineVariant.withOpacity(0.6)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _indicadorViveiro(
                    context,
                    'Biomassa',
                    _valorOuTraco(resumo.biomassaKg, 'kg'),
                  ),
                  _indicadorViveiro(
                    context,
                    'Ração/dia',
                    _valorOuTraco(resumo.racaoDiaKg, 'kg'),
                  ),
                  _indicadorViveiro(
                    context,
                    'FCA proj.',
                    resumo.fcaProjetado == null
                        ? '—'
                        : _fmt(resumo.fcaProjetado!),
                  ),
                ],
              ),
              if (resumo.biomassaKg == null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: cores.onSurfaceVariant),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Complete densidade e biometria para ver as estimativas.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cores.primary),
                      ),
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

  Widget _indicadorViveiro(BuildContext context, String rotulo, String valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _secaoDespesca(
    BuildContext context,
    AppState state,
    List<ResumoViveiro> resumos, {
    required double pesoAlvo,
    required double precoKg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previsão de despesca',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Estimativa baseada no crescimento registrado nas biometrias.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.trending_up_rounded,
                color: Theme.of(context).colorScheme.primary),
          ],
        ),
        const SizedBox(height: 12),
        _configuracaoDespesca(context),
        const SizedBox(height: 12),
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
                mainAxisExtent: 238,
              ),
              itemCount: state.viveiros.length,
              itemBuilder: (context, index) {
                final viveiro = state.viveiros[index];
                final previsao = preverDespesca(
                  viveiro,
                  state.listarBiometrias(viveiro.id),
                  pesoAlvoG: pesoAlvo,
                  precoPorKg: precoKg,
                );
                return _cardDespesca(
                  context,
                  resumos[index],
                  previsao,
                  pesoAlvo: pesoAlvo,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _configuracaoDespesca(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: cores.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget campoPeso() => TextField(
                  controller: _pesoAlvo,
                  onChanged: (_) => setState(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso-alvo',
                    suffixText: 'g',
                    prefixIcon: Icon(Icons.balance_rounded),
                  ),
                );
            Widget campoPreco() => TextField(
                  controller: _precoKg,
                  onChanged: (_) => setState(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço de venda',
                    prefixText: 'R\$ ',
                    suffixText: '/kg',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: cores.primary),
                    const SizedBox(width: 8),
                    const Text('Parâmetros da estimativa',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                if (constraints.maxWidth >= 560)
                  Row(
                    children: [
                      Expanded(child: campoPeso()),
                      const SizedBox(width: 12),
                      Expanded(child: campoPreco()),
                    ],
                  )
                else
                  Column(
                    children: [
                      SizedBox(width: double.infinity, child: campoPeso()),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: campoPreco()),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardDespesca(
    BuildContext context,
    ResumoViveiro resumo,
    PrevisaoDespesca? previsao, {
    required double pesoAlvo,
  }) {
    final cores = Theme.of(context).colorScheme;
    final alvoAtingido =
        resumo.pesoMedioG != null && resumo.pesoMedioG! >= pesoAlvo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cores.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sailing_rounded,
                      color: cores.onPrimaryContainer, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resumo.viveiro.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${_fmt(pesoAlvo)} g'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (previsao == null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cores.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        alvoAtingido
                            ? Icons.task_alt_rounded
                            : Icons.insights_outlined,
                        color: cores.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alvoAtingido
                            ? 'O peso-alvo já foi alcançado.'
                            : 'Registre ao menos duas biometrias com evolução de peso para gerar a previsão.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  _dadoDespesca(
                    context,
                    'Tempo restante',
                    '${previsao.diasParaAlvo} dias',
                    Icons.timelapse_rounded,
                  ),
                  _dadoDespesca(
                    context,
                    'Data estimada',
                    _data(previsao.dataDespesca),
                    Icons.event_available_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: cores.outlineVariant),
              const SizedBox(height: 14),
              Row(
                children: [
                  _dadoDespesca(
                    context,
                    'Produção',
                    _valorOuTraco(previsao.producaoKg, 'kg'),
                    Icons.inventory_2_outlined,
                  ),
                  _dadoDespesca(
                    context,
                    'Receita estimada',
                    previsao.receitaEstimada == null
                        ? '—'
                        : 'R\$ ${_fmt(previsao.receitaEstimada!)}',
                    Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
              if (previsao.producaoKg == null) ...[
                const SizedBox(height: 12),
                Text(
                  'Cadastre a densidade para estimar produção e receita.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cores.onSurfaceVariant),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _dadoDespesca(
    BuildContext context,
    String rotulo,
    String valor,
    IconData icon,
  ) {
    final cor = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: cor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
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

  double _numero(TextEditingController controller, double padrao) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ??
        padrao;
  }

  String _valorOuTraco(double? valor, String unidade) {
    return valor == null ? '—' : '${_fmt(valor)} $unidade';
  }

  String _data(DateTime data) {
    String dois(int valor) => valor.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year}';
  }
}
