import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/modelos.dart';
import '../state/app_state.dart';
import '../widgets/scroll_hide_scaffold.dart';

/// Cadastro/edição de um viveiro (nome, área, densidade opcional).
class ViveiroFormScreen extends StatefulWidget {
  final String? id;
  const ViveiroFormScreen({super.key, this.id});

  @override
  State<ViveiroFormScreen> createState() => _ViveiroFormScreenState();
}

class _ViveiroFormScreenState extends State<ViveiroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _area;
  late final TextEditingController _densidade;
  late final TextEditingController _marca;
  DateTime? _dataPovoamento;
  bool _editando = false;
  bool _preenchido = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController();
    _area = TextEditingController();
    _densidade = TextEditingController();
    _marca = TextEditingController();
    _editando = widget.id != null;
  }

  @override
  void dispose() {
    _nome.dispose();
    _area.dispose();
    _densidade.dispose();
    _marca.dispose();
    super.dispose();
  }

  void _preencher(Viveiro v) {
    _nome.text = v.nome;
    _area.text = _fmt(v.areaHa);
    if (v.densidadePadrao != null) _densidade.text = _fmt(v.densidadePadrao!);
    if (v.marcaRacao != null) _marca.text = v.marcaRacao!;
    _dataPovoamento = v.dataPovoamento;
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final state = context.read<AppState>();
    final area = double.parse(_area.text.trim().replaceAll(',', '.'));
    final densTxt = _densidade.text.trim();
    final densidade =
        densTxt.isEmpty ? null : double.tryParse(densTxt.replaceAll(',', '.'));
    final marca = _marca.text.trim();
    final marcaRacao = marca.isEmpty ? null : marca;

    final vivo = state.porId(widget.id);
    final v = vivo != null
        ? vivo.copiarCom(
            nome: _nome.text.trim(),
            areaHa: area,
            densidadePadrao: densidade,
            marcaRacao: marcaRacao,
            dataPovoamento: _dataPovoamento,
          )
        : Viveiro(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            nome: _nome.text.trim(),
            areaHa: area,
            densidadePadrao: densidade,
            marcaRacao: marcaRacao,
            dataPovoamento: _dataPovoamento,
            criadoEm: DateTime.now(),
          );
    await state.salvarViveiro(v);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_editando && !_preenchido) {
      final vivo = state.porId(widget.id);
      if (vivo != null) {
        _preencher(vivo);
        _preenchido = true;
      }
    }
    return ScrollHideScaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar viveiro' : 'Novo viveiro')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                labelText: 'Nome do viveiro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(
                labelText: 'Área',
                suffixText: 'ha',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (val == null || val <= 0) {
                  return 'Informe uma área válida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _densidade,
              decoration: const InputDecoration(
                labelText: 'Densidade padrão (opcional)',
                suffixText: 'cam/m²',
                border: OutlineInputBorder(),
                helperText:
                    'Usada para pré-preencher as calculadoras de área/densidade.',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marca,
              decoration: const InputDecoration(
                labelText: 'Marca da ração (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
                helperText:
                    'Usada para pré-preencher o cálculo de arraçoamento.',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Data de povoamento (opcional)'),
              subtitle: Text(
                _dataPovoamento == null
                    ? 'Informe quando o ciclo começou'
                    : '${_dataPovoamento!.day.toString().padLeft(2, '0')}/'
                        '${_dataPovoamento!.month.toString().padLeft(2, '0')}/'
                        '${_dataPovoamento!.year}',
              ),
              trailing: TextButton(
                onPressed: _escolherData,
                child: const Text('Alterar'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
