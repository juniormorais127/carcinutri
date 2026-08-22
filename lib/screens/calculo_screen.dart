import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/calculadoras.dart';
import '../domain/modelos.dart';
import '../state/app_state.dart';
import '../widgets/campo_calculo.dart';
import '../widgets/result_card.dart';

/// Tela genérica de cálculo: campos de entrada → resultado → salvar.
/// Um viveiro pode ser selecionado (ou passado via [viveiroId]) para
/// pré-preencher área/densidade/peso médio a partir dos dados cadastrados.
class CalculoScreen extends StatefulWidget {
  final String tipo;
  final String? viveiroId;
  const CalculoScreen({super.key, required this.tipo, this.viveiroId});

  @override
  State<CalculoScreen> createState() => _CalculoScreenState();
}

class _CalculoScreenState extends State<CalculoScreen> {
  late final DefinicaoCalculadora _def;
  late final Map<String, TextEditingController> _ctrl;
  String? _viveiroId;
  ResultadoCalculo? _resultado;

  @override
  void initState() {
    super.initState();
    _def = calculadorasPorTipo[TipoCalculadora.values.byName(widget.tipo)]!;
    _ctrl = {};
    for (final c in _def.campos) {
      final tc = TextEditingController();
      if (c.valorPadrao != null) tc.text = _fmt(c.valorPadrao!);
      _ctrl[c.id] = tc;
    }
    if (widget.viveiroId != null) {
      final v = context.read<AppState>().porId(widget.viveiroId);
      if (v != null) _aplicarViveiro(v, notificar: false);
    }
  }

  @override
  void dispose() {
    for (final tc in _ctrl.values) {
      tc.dispose();
    }
    super.dispose();
  }

  void _aplicarViveiro(Viveiro? v, {bool notificar = true}) {
    void aplica() {
      _viveiroId = v?.id;
      _resultado = null;
      final b = v == null ? null : context.read<AppState>().ultimaBiometria(v.id);
      for (final c in _def.campos) {
        if (c.chaveViveiro == 'area') {
          _ctrl[c.id]!.text = v == null ? '' : _fmt(v.areaHa);
        } else if (c.chaveViveiro == 'densidade') {
          _ctrl[c.id]!.text =
              v?.densidadePadrao != null ? _fmt(v!.densidadePadrao!) : '';
        } else if (c.chaveViveiro == 'peso_medio') {
          _ctrl[c.id]!.text = b == null ? '' : _fmt(b.pesoMedio);
        } else if (c.chaveViveiro == 'marca') {
          _ctrl[c.id]!.text = v?.marcaRacao ?? '';
        } else if (c.id == 'biomassa') {
          // Arraçoamento: usa a biomassa computada do viveiro (última biometria).
          final dens = v?.densidadePadrao;
          if (v != null && dens != null && b != null) {
            _ctrl[c.id]!.text =
                _fmt(calcularBiomassa(dens, v.areaHa, b.pesoMedio));
          } else {
            _ctrl[c.id]!.text =
                c.valorPadrao != null ? _fmt(c.valorPadrao!) : '';
          }
        }
      }
    }
    if (notificar) {
      setState(aplica);
    } else {
      aplica();
    }
  }

  Map<String, double> _lerEntradas() {
    final entradas = <String, double>{};
    for (final c in _def.campos) {
      if (c.texto) continue; // campos de texto não entram no cálculo numérico
      final txt = _ctrl[c.id]!.text.trim().replaceAll(',', '.');
      final val = double.tryParse(txt);
      if (val != null) entradas[c.id] = val;
    }
    return entradas;
  }

  /// Campos de texto (ex.: marca da ração) para gravar junto do resultado.
  Map<String, String> _lerTextos() {
    final textos = <String, String>{};
    for (final c in _def.campos) {
      if (!c.texto) continue;
      final txt = _ctrl[c.id]!.text.trim();
      if (txt.isNotEmpty) textos[c.rotulo] = txt;
    }
    return textos;
  }

  void _calcular() {
    try {
      final r = _def.calcular(_lerEntradas());
      setState(() => _resultado = r);
    } on CalculoInvalido catch (e) {
      setState(() => _resultado = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _salvar() async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final r = _resultado;
    if (r == null) return;
    final calculo = Calculo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      viveiroId: _viveiroId,
      tipo: _def.tipo,
      entradas: _lerEntradas(),
      resultado: {
        for (final i in r.itens) i.rotulo: i.valor,
        ..._lerTextos(),
      },
      criadoEm: DateTime.now(),
    );
    await state.salvarCalculo(calculo);
    messenger.showSnackBar(const SnackBar(content: Text('Cálculo salvo.')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('${_def.icone} ${_def.titulo}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_def.descricao, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (state.viveiros.isNotEmpty) ...[
            _seletorViveiro(state),
            const SizedBox(height: 16),
          ],
          for (final c in _def.campos) ...[
            CampoCalculo(
                controller: _ctrl[c.id]!,
                rotulo: c.rotulo,
                unidade: c.unidade,
                texto: c.texto),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 16),
            ResultCard(resultado: _resultado!),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar cálculo'),
            ),
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
      onChanged: (id) =>
          _aplicarViveiro(id == null || id.isEmpty ? null : state.porId(id)),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
