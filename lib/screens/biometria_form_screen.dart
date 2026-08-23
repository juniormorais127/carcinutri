import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/modelos.dart';
import '../domain/qualidade_agua.dart';
import '../state/app_state.dart';
import '../widgets/responsive_layout.dart';

/// Registra uma biometria (amostra + contagem → peso médio) em um viveiro,
/// junto da qualidade de água medida na mesma visita semanal (boas práticas).
class BiometriaFormScreen extends StatefulWidget {
  final String? viveiroId;
  const BiometriaFormScreen({super.key, this.viveiroId});

  @override
  State<BiometriaFormScreen> createState() => _BiometriaFormScreenState();
}

class _BiometriaFormScreenState extends State<BiometriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _peso;
  late final TextEditingController _contagem;
  late final TextEditingController _od;
  late final TextEditingController _ph;
  late final TextEditingController _temperatura;
  late final TextEditingController _amonia;
  late final TextEditingController _nitrito;
  late final TextEditingController _alcalinidade;
  DateTime _data = DateTime.now();
  String? _viveiroId;

  @override
  void initState() {
    super.initState();
    _peso = TextEditingController();
    _contagem = TextEditingController();
    _od = TextEditingController();
    _ph = TextEditingController();
    _temperatura = TextEditingController();
    _amonia = TextEditingController();
    _nitrito = TextEditingController();
    _alcalinidade = TextEditingController();
    _viveiroId = widget.viveiroId;
  }

  @override
  void dispose() {
    _peso.dispose();
    _contagem.dispose();
    _od.dispose();
    _ph.dispose();
    _temperatura.dispose();
    _amonia.dispose();
    _nitrito.dispose();
    _alcalinidade.dispose();
    super.dispose();
  }

  double? get _pesoMedio {
    final p = double.tryParse(_peso.text.trim().replaceAll(',', '.'));
    final n = int.tryParse(_contagem.text.trim());
    if (p == null || n == null || p <= 0 || n <= 0) return null;
    return p * 1000 / n;
  }

  double? _parseDouble(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// Constrói a avaliação de água a partir dos campos preenchidos (ao vivo).
  AvaliacaoQualidade? get _avaliacaoAgua {
    final q = QualidadeAgua(
      id: 'preview',
      viveiroId: _viveiroId ?? '',
      data: _data,
      od: _parseDouble(_od),
      ph: _parseDouble(_ph),
      temperatura: _parseDouble(_temperatura),
      amonia: _parseDouble(_amonia),
      nitrito: _parseDouble(_nitrito),
      alcalinidade: _parseDouble(_alcalinidade),
    );
    if (q.od == null &&
        q.ph == null &&
        q.temperatura == null &&
        q.amonia == null &&
        q.nitrito == null &&
        q.alcalinidade == null) {
      return null;
    }
    return avaliarQualidadeAgua(q);
  }

  Future<void> _escolherData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    final viveiroId = _viveiroId;
    if (viveiroId == null) {
      messenger
          .showSnackBar(const SnackBar(content: Text('Selecione um viveiro.')));
      return;
    }
    final agora = DateTime.now().microsecondsSinceEpoch.toString();
    final b = Biometria(
      id: agora,
      viveiroId: viveiroId,
      data: _data,
      pesoAmostraKg: double.parse(_peso.text.trim().replaceAll(',', '.')),
      nAmostrado: int.parse(_contagem.text.trim()),
    );
    await state.salvarBiometria(b);

    // Qualidade de água da mesma visita (se algum parâmetro foi informado).
    final q = QualidadeAgua(
      id: agora,
      viveiroId: viveiroId,
      data: _data,
      od: _parseDouble(_od),
      ph: _parseDouble(_ph),
      temperatura: _parseDouble(_temperatura),
      amonia: _parseDouble(_amonia),
      nitrito: _parseDouble(_nitrito),
      alcalinidade: _parseDouble(_alcalinidade),
    );
    if (q.od != null ||
        q.ph != null ||
        q.temperatura != null ||
        q.amonia != null ||
        q.nitrito != null ||
        q.alcalinidade != null) {
      await state.salvarQualidadeAgua(q);
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vivo = state.porId(_viveiroId);
    final pesoMedio = _pesoMedio;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar biometria')),
      body: Form(
        key: _formKey,
        child: ResponsiveListView(
          maxWidth: 760,
          children: [
            if (widget.viveiroId == null) ...[
              DropdownButtonFormField<String>(
                value: _viveiroId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Viveiro',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: '', child: Text('Selecione')),
                  ...state.viveiros.map((v) => DropdownMenuItem<String>(
                      value: v.id, child: Text(v.nome))),
                ],
                onChanged: (id) => setState(
                    () => _viveiroId = (id == null || id.isEmpty) ? null : id),
              ),
              const SizedBox(height: 16),
            ] else
              Text('Viveiro: ${vivo?.nome ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data'),
              subtitle: Text('${_data.day.toString().padLeft(2, '0')}/'
                  '${_data.month.toString().padLeft(2, '0')}/${_data.year}'),
              trailing: TextButton(
                onPressed: _escolherData,
                child: const Text('Alterar'),
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _peso,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso da amostra',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (val == null || val <= 0) {
                  return 'Informe o peso da amostra.';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contagem,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nº de camarões amostrados',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final val = int.tryParse((v ?? ''));
                if (val == null || val <= 0) {
                  return 'Informe quantos camarões foram amostrados.';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (pesoMedio != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Peso médio'),
                      Text(
                        '${_fmt(pesoMedio)} g',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _secaoQualidadeAgua(context, _avaliacaoAgua),
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

  Widget _campoAgua(TextEditingController c, String rotulo, String unidade) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: rotulo,
        suffixText: unidade.isEmpty ? null : unidade,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _secaoQualidadeAgua(BuildContext context, AvaliacaoQualidade? av) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Qualidade de água (boas práticas)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Medida na mesma visita da biometria. Os parâmetros informados '
              'são avaliados contra faixas recomendadas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                    width: 140, child: _campoAgua(_od, 'Oxigênio', 'mg/L')),
                SizedBox(width: 100, child: _campoAgua(_ph, 'pH', '')),
                SizedBox(
                    width: 120, child: _campoAgua(_temperatura, 'Temp.', '°C')),
                SizedBox(
                    width: 120, child: _campoAgua(_amonia, 'Amônia', 'mg/L')),
                SizedBox(
                    width: 120, child: _campoAgua(_nitrito, 'Nitrito', 'mg/L')),
                SizedBox(
                    width: 150,
                    child: _campoAgua(_alcalinidade, 'Alcalinidade', 'mg/L')),
              ],
            ),
            if (av != null) ...[
              const SizedBox(height: 12),
              _statusGeral(av.statusGeral),
              const SizedBox(height: 8),
              for (final p in av.parametros)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Text('${p.rotulo}: ${_fmt(p.valor)} ${p.unidade}'),
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

  Widget _statusGeral(StatusQualidade s) {
    final cor = _cor(s);
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
    final cor = _cor(s);
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

  Color _cor(StatusQualidade s) {
    switch (s) {
      case StatusQualidade.ok:
        return Colors.green;
      case StatusQualidade.atencao:
        return Colors.orange;
      case StatusQualidade.critico:
        return Colors.red;
    }
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
