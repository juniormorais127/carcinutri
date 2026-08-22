import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/calculadoras.dart';
import '../domain/modelos.dart';
import '../domain/qualidade_agua.dart';
import '../state/app_state.dart';
import '../widgets/scroll_hide_scaffold.dart';

/// Painel do viveiro: biometria → biomassa → ração diária + boas práticas.
/// Fluxo principal de trabalho, reaproveitando os dados já cadastrados.
class ViveiroPainelScreen extends StatefulWidget {
  final String id;
  const ViveiroPainelScreen({super.key, required this.id});

  @override
  State<ViveiroPainelScreen> createState() => _ViveiroPainelScreenState();
}

class _ViveiroPainelScreenState extends State<ViveiroPainelScreen> {
  final _taxa = TextEditingController(text: '5');
  final _fmtReg = RegExp(r'\.?0+$');

  @override
  void dispose() {
    _taxa.dispose();
    super.dispose();
  }

  String _fmt(double v) => _fmtReg.hasMatch(v.toStringAsFixed(2))
      ? v.toStringAsFixed(2).replaceFirst(_fmtReg, '')
      : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vivo = state.porId(widget.id);
    if (vivo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viveiro')),
        body: const Center(child: Text('Viveiro não encontrado.')),
      );
    }

    final ultima = state.ultimaBiometria(vivo.id);
    final ultimaAgua = state.ultimaQualidadeAgua(vivo.id);
    final dens = vivo.densidadePadrao;
    final biomassa = (dens != null && ultima != null)
        ? calcularBiomassa(dens, vivo.areaHa, ultima.pesoMedio)
        : null;
    final taxa = double.tryParse(_taxa.text.trim().replaceAll(',', '.'));
    final racao = (biomassa != null && taxa != null && taxa > 0)
        ? racaoPorDia(biomassa, taxa)
        : null;
    final faltandoDens = dens == null;
    final faltandoBio = ultima == null;

    return ScrollHideScaffold(
      appBar: AppBar(
        title: Text(vivo.nome),
        actions: [
          IconButton(
            tooltip: 'Gráfico de crescimento',
            icon: const Icon(Icons.show_chart),
            onPressed: () => context.push('/crescimento/${vivo.id}'),
          ),
          IconButton(
            tooltip: 'Histórico de cálculos',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/historico/${vivo.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (o) => _acao(context, state, vivo, o),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar viveiro')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cabecalho(vivo),
          const SizedBox(height: 12),
          _cardBiometria(context, vivo, ultima),
          const SizedBox(height: 12),
          _cardQualidadeAgua(context, vivo, ultimaAgua),
          const SizedBox(height: 12),
          if (biomassa != null) ...[
            _cardBiomassa(context, biomassa, ultima),
            const SizedBox(height: 12),
            _cardRacao(context, biomassa, taxa, racao, vivo, ultima),
            const SizedBox(height: 12),
            _botoesCalculadoras(context, vivo),
          ] else
            _cardAviso(context, faltandoDens: faltandoDens, faltandoBio: faltandoBio),
        ],
      ),
    );
  }

  Widget _cabecalho(Viveiro v) {
    final dens = v.densidadePadrao;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.water, size: 32),
        title: Text(v.nome),
        subtitle: Text(
          'Área: ${_fmt(v.areaHa)} ha'
          '${dens != null ? ' · Densidade: ${_fmt(dens)} cam/m²' : ''}'
          '${v.marcaRacao != null ? ' · Ração: ${v.marcaRacao}' : ''}',
        ),
      ),
    );
  }

  Widget _cardBiometria(BuildContext context, Viveiro v, Biometria? ultima) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Peso médio do camarão',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => context.push('/biometria/${v.id}'),
                  child: const Text('Registrar'),
                ),
              ],
            ),
            if (ultima == null)
              const Text('Nenhuma biometria registrada ainda.')
            else ...[
              Text('${_fmt(ultima.pesoMedio)} g',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Biometria de ${_data(ultima.data)} · '
                'amostra ${_fmt(ultima.pesoAmostraKg)} kg / '
                '${ultima.nAmostrado} camarões',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardQualidadeAgua(BuildContext context, Viveiro v,
      QualidadeAgua? ultimaAgua) {
    final av = ultimaAgua == null ? null : avaliarQualidadeAgua(ultimaAgua);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Qualidade de água',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => context.push('/biometria/${v.id}'),
                  child: const Text('Registrar'),
                ),
              ],
            ),
            if (av == null)
              const Text('Nenhuma avaliação registrada ainda. '
                  'Registre junto da biometria semanal (boas práticas).')
            else ...[
              Text('Última: ${_data(ultimaAgua!.data)}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              _statusGeral(av.statusGeral),
              const SizedBox(height: 8),
              for (final p in av.parametros)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            '${p.rotulo}: ${_fmt(p.valor)} ${p.unidade}'),
                      ),
                      _chip(p.status),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardBiomassa(
      BuildContext context, double biomassa, Biometria? ultima) {
    return _valoresCard(
      context,
      icone: '🪣',
      titulo: 'Biomassa (estimada)',
      itens: [
        ('Biomassa total', '${_fmt(biomassa)} kg', true),
        ('Base',
            'biometria de ${ultima == null ? '—' : _data(ultima.data)} × '
            'área × densidade',
            false),
      ],
    );
  }

  Widget _cardRacao(BuildContext context, double biomassa, double? taxa,
      double? racao, Viveiro v, Biometria? ultima) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ração do dia',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taxa,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Taxa de alimentação',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                if (racao != null)
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_fmt(racao)} kg/dia',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Base: biometria de ${ultima == null ? '—' : _data(ultima.data)} '
              '(${_fmt(biomassa)} kg de biomassa)'
              '${v.marcaRacao != null ? ' · Ração: ${v.marcaRacao}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusGeral(StatusQualidade s) {
    final cor = _corStatus(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Status geral: ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(rotuloStatus(s),
              style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }

  Widget _chip(StatusQualidade s) {
    final cor = _corStatus(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rotuloStatus(s),
        style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 12),
      ),
    );
  }

  Color _corStatus(StatusQualidade s) {
    switch (s) {
      case StatusQualidade.ok:
        return Colors.green;
      case StatusQualidade.atencao:
        return Colors.orange;
      case StatusQualidade.critico:
        return Colors.red;
    }
  }

  Widget _botoesCalculadoras(BuildContext context, Viveiro v) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => context
              .push('/calculadora/biomassa?viveiro=${v.id}'),
          icon: const Icon(Icons.calculate),
          label: const Text('Calcular biomassa'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => context
              .push('/calculadora/arracoamento?viveiro=${v.id}'),
          icon: const Icon(Icons.restaurant),
          label: const Text('Calcular ração'),
        ),
      ],
    );
  }

  Widget _cardAviso(BuildContext context,
      {required bool faltandoDens, required bool faltandoBio}) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para calcular biomassa e ração, cadastre:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (faltandoDens)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.arrow_forward),
                title: const Text('A densidade padrão do viveiro'),
                trailing: TextButton(
                  onPressed: () => context.push('/viveiro/${widget.id}'),
                  child: const Text('Editar'),
                ),
              ),
            if (faltandoBio)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.arrow_forward),
                title: const Text('A primeira biometria'),
                trailing: TextButton(
                  onPressed: () => context.push('/biometria/${widget.id}'),
                  child: const Text('Registrar'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _valoresCard(BuildContext context,
      {required String icone,
      required String titulo,
      required List<(String, String, bool)> itens}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$icone $titulo',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final (rotulo, valor, destaque) in itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rotulo),
                    Text(valor,
                        style: destaque
                            ? Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)
                            : null),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acao(BuildContext context, AppState state, Viveiro v,
      String opcao) async {
    switch (opcao) {
      case 'editar':
        context.push('/viveiro/${v.id}');
      case 'excluir':
        final confirma = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir viveiro?'),
            content: Text('Excluir "${v.nome}" e todos os seus dados?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Excluir')),
            ],
          ),
        );
        if (confirma == true) {
          await state.removerViveiro(v.id);
          if (context.mounted) context.pop();
        }
    }
  }

  String _data(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}/${p2(d.month)}/${d.year}';
  }
}
