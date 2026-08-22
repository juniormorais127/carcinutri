import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/calculadoras.dart';
import '../domain/modelos.dart';
import '../state/app_state.dart';
import '../widgets/scroll_hide_scaffold.dart';

/// Histórico de cálculos — de um viveiro específico (por id) ou de todos.
class HistoricoScreen extends StatelessWidget {
  final String? id;
  const HistoricoScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final viveiro = state.porId(id);
    final calculos = state.calculosDoViveiro(id);

    return ScrollHideScaffold(
      appBar: AppBar(
        title: Text(viveiro != null ? 'Histórico · ${viveiro.nome}' : 'Histórico'),
      ),
      body: calculos.isEmpty
          ? const _Vazio()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: calculos.length,
              itemBuilder: (context, i) => _item(context, state, calculos[i]),
            ),
    );
  }

  Widget _item(BuildContext context, AppState state, Calculo c) {
    final def = calculadorasPorTipo[c.tipo];
    final nomeViveiro =
        c.viveiroId == null ? '' : state.porId(c.viveiroId)?.nome ?? '';
    final quando = _dataHora(c.criadoEm);
    final principal = c.resultado.entries.isNotEmpty
        ? c.resultado.entries.last
        : null;

    return Card(
      child: ListTile(
        leading: Text(def?.icone ?? '🧮',
            style: const TextStyle(fontSize: 24)),
        title: Text(def?.titulo ?? c.tipo.name),
        subtitle: Text([
          if (principal != null) '${principal.key}: ${principal.value}',
          if (nomeViveiro.isNotEmpty) nomeViveiro,
          quando,
        ].join(' · ')),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (o) {
            if (o == 'excluir') state.removerCalculo(c.id);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  String _dataHora(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}/${p2(d.month)}/${d.year} ${p2(d.hour)}:${p2(d.minute)}';
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('Nenhum cálculo salvo.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push('/calculadoras'),
            icon: const Icon(Icons.calculate),
            label: const Text('Ver calculadoras'),
          ),
        ],
      ),
    );
  }
}
