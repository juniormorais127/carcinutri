import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/modelos.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('AQUACENSO')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/viveiro'),
        icon: const Icon(Icons.add),
        label: const Text('Novo viveiro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardCalculadoras(context),
          const SizedBox(height: 16),
          Text('Viveiros',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.viveiros.isEmpty)
            _vazio(context)
          else
            ...state.viveiros.map((v) => _viveiroTile(context, state, v)),
        ],
      ),
    );
  }

  Widget _cardCalculadoras(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.calculate, size: 32),
        title: const Text('Calculadoras',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('12 calculadoras de carcinicultura, sem internet'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/calculadoras'),
      ),
    );
  }

  Widget _vazio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.grain, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Nenhum viveiro cadastrado.\nToque em "Novo viveiro" para começar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _viveiroTile(
      BuildContext context, AppState state, Viveiro v) {
    final dens = v.densidadePadrao;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.water),
        title: Text(v.nome),
        subtitle: Text(
          'Área: ${_fmt(v.areaHa)} ha'
          '${dens != null ? ' · Densidade: ${_fmt(dens)} cam/m²' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (opcao) => _acao(context, state, v, opcao),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'historico', child: Text('Histórico')),
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
        onTap: () => context.push('/painel/${v.id}'),
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
