import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/modelos.dart';
import '../domain/projecao.dart';
import '../state/app_state.dart';

/// Aba Projeção: arraçoamento de todo o ciclo + crescimento esperado,
/// comparado com a biometria registrada.
class ProjecaoScreen extends StatefulWidget {
  const ProjecaoScreen({super.key});

  @override
  State<ProjecaoScreen> createState() => _ProjecaoScreenState();
}

class _ProjecaoScreenState extends State<ProjecaoScreen> {
  final _area = TextEditingController();
  final _densidade = TextEditingController();
  final _pesoInicial = TextEditingController(text: '0,05');
  final _peso70 = TextEditingController(text: '9,5');
  final _sobrevivencia = TextEditingController(text: '80');
  String? _viveiroId;
  DateTime? _dataPovoamento;
  ProjecaoCiclo? _ciclo;

  @override
  void initState() {
    super.initState();
    if (Provider.of<AppState>(context, listen: false).viveiros.isNotEmpty) {
      // Sem viveiro selecionado; preenche a data com hoje por padrão.
      _dataPovoamento = DateTime.now();
    }
  }

  @override
  void dispose() {
    _area.dispose();
    _densidade.dispose();
    _pesoInicial.dispose();
    _peso70.dispose();
    _sobrevivencia.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  void _aplicarViveiro(Viveiro? v) {
    _viveiroId = v?.id;
    _ciclo = null;
    _area.text = v == null ? '' : _fmt(v.areaHa);
    _densidade.text =
        v?.densidadePadrao != null ? _fmt(v!.densidadePadrao!) : '';
    _dataPovoamento = v?.dataPovoamento ?? DateTime.now();
  }

  Future<void> _escolherData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataPovoamento ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selecionada != null) {
      setState(() => _dataPovoamento = selecionada);
    }
  }

  void _calcular() {
    final area = _parse(_area);
    final densidade = _parse(_densidade);
    final peso70 = _parse(_peso70);
    final sobrevivencia = _parse(_sobrevivencia);
    final messenger = ScaffoldMessenger.of(context);
    if (area == null || area <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Informe a área do viveiro (ha).')));
      return;
    }
    if (densidade == null || densidade <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Informe a densidade (cam/m²).')));
      return;
    }
    if (peso70 == null || peso70 <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Informe o peso esperado aos 70 dias.')));
      return;
    }
    final sobrev =
        (sobrevivencia == null || sobrevivencia <= 0 || sobrevivencia > 100)
            ? 80.0
            : sobrevivencia;
    final pesoInicial = _parse(_pesoInicial) ?? 0.05;
    setState(() {
      _ciclo = projetarCiclo(
        areaHa: area,
        densidade: densidade,
        sobrevivenciaPct: sobrev,
        pesoInicial: pesoInicial,
        peso70: peso70,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final diaAtual = _dataPovoamento == null
        ? null
        : DateTime.now().difference(_dataPovoamento!).inDays;
    return Scaffold(
      appBar: AppBar(title: const Text('Projeção do ciclo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Previsão do arraçoamento diário e do crescimento esperado '
            '(referência: 9–10 g aos 70 dias).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (state.viveiros.isNotEmpty) ...[
            _seletorViveiro(state),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _area,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Área do viveiro',
              suffixText: 'ha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _densidade,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Densidade',
              suffixText: 'cam/m²',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pesoInicial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso inicial',
              suffixText: 'g',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _peso70,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso esperado aos 70 dias',
              suffixText: 'g',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sobrevivencia,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Sobrevivência esperada',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Data de povoamento'),
            subtitle: Text(
              _dataPovoamento == null
                  ? 'Informe quando o ciclo começou'
                  : '${_dataPovoamento!.day.toString().padLeft(2, '0')}/'
                      '${_dataPovoamento!.month.toString().padLeft(2, '0')}/'
                      '${_dataPovoamento!.year}'
                      ' (dia ${diaAtual ?? 0} do ciclo)',
            ),
            trailing: TextButton(
              onPressed: _escolherData,
              child: const Text('Alterar'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular projeção'),
          ),
          if (_ciclo != null) ...[
            const SizedBox(height: 16),
            _resumo(context, _ciclo!),
            const SizedBox(height: 16),
            _planilha(context, _ciclo!, diaAtual: diaAtual),
            const SizedBox(height: 16),
            _comparacao(context, state, diaAtual),
          ],
        ],
      ),
    );
  }

  Widget _seletorViveiro(AppState state) {
    return DropdownButtonFormField<String>(
      value: _viveiroId ?? '',
      decoration: const InputDecoration(
        labelText: 'Viveiro (opcional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.water),
      ),
      items: [
        const DropdownMenuItem<String>(value: '', child: Text('Nenhum')),
        ...state.viveiros.map(
          (v) => DropdownMenuItem<String>(value: v.id, child: Text(v.nome)),
        ),
      ],
      onChanged: (id) => setState(() =>
          _aplicarViveiro(id == null || id.isEmpty ? null : state.porId(id))),
    );
  }

  Widget _resumo(BuildContext context, ProjecaoCiclo c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo do ciclo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _linhaResumo('Camarões', _fmt(c.nCamaroes.toDouble())),
            _linhaResumo('Peso final esperado', '${_fmt(c.pesoFinal)} g'),
            _linhaResumo('Ração total do ciclo', '${_fmt(c.racaoTotalKg)} kg',
                destaque: true),
            _linhaResumo('Ração média/dia', '${_fmt(c.racaoMediaDiaKg)} kg'),
            _linhaResumo('FCA estimado', _fmt(c.fca)),
          ],
        ),
      ),
    );
  }

  Widget _linhaResumo(String rotulo, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo),
          Text(valor,
              style: destaque
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null),
        ],
      ),
    );
  }

  Widget _planilha(
      BuildContext context, ProjecaoCiclo c, {required int? diaAtual}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Planilha diária',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 32,
                columns: const [
                  DataColumn(label: Text('Dia')),
                  DataColumn(label: Text('Peso (g)')),
                  DataColumn(label: Text('Taxa %')),
                  DataColumn(label: Text('Biomassa (kg)')),
                  DataColumn(label: Text('Ração (kg/dia)')),
                  DataColumn(label: Text('Acum. (kg)')),
                ],
                rows: [
                  for (final d in c.dias)
                    DataRow(
                      color: d.dia == diaAtual
                          ? MaterialStatePropertyAll(
                              Theme.of(context).colorScheme.primaryContainer)
                          : null,
                      cells: [
                        DataCell(Text('${d.dia}')),
                        DataCell(Text(_fmt(d.pesoMedio))),
                        DataCell(Text(_fmt(d.taxaPct))),
                        DataCell(Text(_fmt(d.biomassaKg))),
                        DataCell(Text(_fmt(d.racaoKgDia))),
                        DataCell(Text(_fmt(d.racaoAcumuladaKg))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparacao(BuildContext context, AppState state, int? diaAtual) {
    final v = _viveiroId == null ? null : state.porId(_viveiroId);
    final dataPovo = v?.dataPovoamento ?? _dataPovoamento;
    final biometrias = _viveiroId == null
        ? const <Biometria>[]
        : state.listarBiometrias(_viveiroId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crescimento esperado × biometria',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_viveiroId == null)
              const Text('Selecione um viveiro para comparar as biometrias.')
            else if (dataPovo == null)
              const Text('Cadastre a data de povoamento no viveiro para '
                  'calcular a idade do camarão.')
            else if (biometrias.isEmpty)
              const Text('Nenhuma biometria registrada ainda.')
            else
              for (final b in biometrias) ...[
                _linhaComparacao(context, b, dataPovo),
                const SizedBox(height: 4),
              ],
          ],
        ),
      ),
    );
  }

  Widget _linhaComparacao(BuildContext context, Biometria b, DateTime povo) {
    final idade = b.data.difference(povo).inDays;
    final peso70 = _parse(_peso70) ?? 9.5;
    final pesoInicial = _parse(_pesoInicial) ?? 0.05;
    final esperado = pesoEsperado(idade,
        pesoInicial: pesoInicial, peso70: peso70);
    final cmp = compararComEsperado(pesoReal: b.pesoMedio, pesoEsperado: esperado);
    final cor = _corStatus(cmp.status);
    final sinal = cmp.difG >= 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_data(b.data)} · idade $idade dias',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text('Real: ${_fmt(b.pesoMedio)} g · Esperado: ${_fmt(esperado)} g '
            '($sinal${_fmt(cmp.difG)} g, $sinal${_fmt(cmp.difPct)}%)',
            style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
      ],
    );
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'acima':
        return Colors.blue;
      case 'abaixo':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _data(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
