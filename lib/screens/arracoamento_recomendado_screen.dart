import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/arracoamento.dart';
import '../domain/calculadoras.dart';
import '../domain/modelos.dart';
import '../state/app_state.dart';
import '../widgets/responsive_layout.dart';

/// Recomendação de arraçoamento (FAO / L. vannamei): quanto fornecer hoje,
/// em quantos tratos e como usar a bandeja, a partir do peso médio atual.
class ArracoamentoRecomendadoScreen extends StatefulWidget {
  final String? viveiroId;
  const ArracoamentoRecomendadoScreen({super.key, this.viveiroId});

  @override
  State<ArracoamentoRecomendadoScreen> createState() =>
      _ArracoamentoRecomendadoScreenState();
}

enum _ModoCamaroes { vivos, povoamento }

enum _ModoTaxa { recomendado, manual }

class _ArracoamentoRecomendadoScreenState
    extends State<ArracoamentoRecomendadoScreen> {
  static const _especie = especieVannamei;

  final _peso = TextEditingController();
  final _nVivos = TextEditingController();
  final _povoados = TextEditingController();
  final _sobrevivencia = TextEditingController(text: '80');
  final _taxaManual = TextEditingController();

  String? _viveiroId;
  _ModoCamaroes _modoCamaroes = _ModoCamaroes.vivos;
  _ModoTaxa _modoTaxa = _ModoTaxa.recomendado;
  int? _nTratos;
  RecomendacaoArracoamento? _resultado;

  @override
  void initState() {
    super.initState();
    if (widget.viveiroId != null) {
      final v = context.read<AppState>().porId(widget.viveiroId);
      if (v != null) _aplicarViveiro(v, notificar: false);
    }
  }

  @override
  void dispose() {
    _peso.dispose();
    _nVivos.dispose();
    _povoados.dispose();
    _sobrevivencia.dispose();
    _taxaManual.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  void _aplicarViveiro(Viveiro? v, {bool notificar = true}) {
    void aplica() {
      _viveiroId = v?.id;
      _resultado = null;
      if (v == null) return;
      final b = context.read<AppState>().ultimaBiometria(v.id);
      if (b != null) _peso.text = _fmt(b.pesoMedio);
      // Conveniência: camarões povoados estimados = densidade × área × 10000.
      if (v.densidadePadrao != null) {
        _povoados.text = _fmt(v.densidadePadrao! * v.areaHa * 10000);
      }
    }

    if (notificar) {
      setState(aplica);
    } else {
      aplica();
    }
  }

  void _calcular() {
    final messenger = ScaffoldMessenger.of(context);
    final peso = _parse(_peso);
    if (peso == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Informe o peso médio (g).')));
      return;
    }

    try {
      final nVivos = _calcularNVivos();
      final r = recomendarArracoamento(
        especie: _especie,
        pesoMedio: peso,
        nVivos: nVivos,
        nTratos: _nTratos,
        taxaManual: _modoTaxa == _ModoTaxa.manual ? _parse(_taxaManual) : null,
      );
      setState(() {
        _resultado = r;
        // Recalculou para uma faixa nova: zera a escolha anterior de tratos.
        _nTratos = null;
      });
    } on CalculoInvalido catch (e) {
      setState(() => _resultado = null);
      messenger.showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  int _calcularNVivos() {
    if (_modoCamaroes == _ModoCamaroes.vivos) {
      final n = _parse(_nVivos);
      if (n == null) {
        throw CalculoInvalido('Informe o nº de camarões vivos.');
      }
      return n.round();
    }
    final povoados = _parse(_povoados);
    final sobrev = _parse(_sobrevivencia);
    if (povoados == null) {
      throw CalculoInvalido('Informe o nº de camarões povoados.');
    }
    if (sobrev == null) {
      throw CalculoInvalido('Informe a sobrevivência (%).');
    }
    return calcularCamaroesVivos(povoados.round(), sobrev);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendação de arraçoamento')),
      body: ResponsiveListView(
        maxWidth: 860,
        children: [
          Text(
            'Camarão-branco-do-Pacífico · fase engorda · base FAO.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (state.viveiros.isNotEmpty) ...[
            _seletorViveiro(state),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _peso,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso médio',
              suffixText: 'g',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_ModoCamaroes>(
            segments: const [
              ButtonSegment(
                  value: _ModoCamaroes.vivos, label: Text('Cam. vivos')),
              ButtonSegment(
                  value: _ModoCamaroes.povoamento,
                  label: Text('Povoou + sobrev.')),
            ],
            selected: {_modoCamaroes},
            onSelectionChanged: (s) => setState(() => _modoCamaroes = s.first),
          ),
          const SizedBox(height: 12),
          if (_modoCamaroes == _ModoCamaroes.vivos)
            TextFormField(
              controller: _nVivos,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nº de camarões vivos',
                border: OutlineInputBorder(),
              ),
            )
          else ...[
            TextFormField(
              controller: _povoados,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Camarões povoados',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sobrevivencia,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Sobrevivência',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SegmentedButton<_ModoTaxa>(
            segments: const [
              ButtonSegment(
                  value: _ModoTaxa.recomendado, label: Text('Recomendado')),
              ButtonSegment(value: _ModoTaxa.manual, label: Text('Manual')),
            ],
            selected: {_modoTaxa},
            onSelectionChanged: (s) => setState(() => _modoTaxa = s.first),
          ),
          if (_modoTaxa == _ModoTaxa.manual) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxaManual,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Taxa definida pelo usuário',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _seletorTratos(),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular recomendação'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 16),
            _alerta(context, _resultado!),
            const SizedBox(height: 16),
            _recomendacao(context, _resultado!),
            const SizedBox(height: 16),
            _bandejas(context, _resultado!),
            const SizedBox(height: 16),
            _comoChegamos(context, _resultado!),
            const SizedBox(height: 16),
            _fonte(context),
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

  Widget _seletorTratos() {
    // Deriva a faixa recomendada do peso digitado (quando disponível) para o
    // nº de tratos acompanhar o peso; senão, do último resultado.
    final peso = _parse(_peso);
    final faixaPeso = peso == null ? null : faixaParaPeso(_especie, peso);
    final min = faixaPeso?.tratosMin ?? _resultado?.tratosMin ?? 4;
    final max = faixaPeso?.tratosMax ?? _resultado?.tratosMax ?? min;
    final minU = min <= 0 ? 4 : min;
    final maxU = max < minU ? minU : max;
    if (_nTratos != null && (_nTratos! < minU || _nTratos! > maxU)) {
      _nTratos = null;
    }
    return DropdownButtonFormField<int>(
      value: _nTratos,
      decoration: InputDecoration(
        labelText: 'Frequência (tratos/dia)',
        helperText: maxU > minU
            ? 'Recomendado: $minU a $maxU tratos/dia'
            : 'Recomendado: $minU trato(s)/dia',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.schedule),
      ),
      items: [
        for (var t = minU; t <= maxU; t++)
          DropdownMenuItem<int>(value: t, child: Text('$t trato(s)/dia')),
      ],
      onChanged: (t) => setState(() => _nTratos = t),
    );
  }

  Widget _alerta(BuildContext context, RecomendacaoArracoamento r) {
    final aviso = r.aviso;
    if (aviso == null) return const SizedBox.shrink();
    final cor = r.status == 'acima'
        ? Colors.orange.shade100
        : r.status == 'abaixo'
            ? Colors.red.shade100
            : Colors.amber.shade100;
    final corTexto = r.status == 'acima'
        ? Colors.orange.shade900
        : r.status == 'abaixo'
            ? Colors.red.shade900
            : Colors.amber.shade900;
    return Card(
      color: cor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Text(aviso,
                  style:
                      TextStyle(color: corTexto, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recomendacao(BuildContext context, RecomendacaoArracoamento r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recomendação de arraçoamento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _linha('Camarões vivos', _fmt(r.nVivos.toDouble())),
            _linha('Peso médio', '${_fmt(r.pesoMedio)} g'),
            _linha('Biomassa', '${_fmt(r.biomassaKg)} kg'),
            _linha('Taxa de alimentação', r.taxaDescricao),
            _linha('Faixa técnica', r.faixaTecnica),
            if (r.status != 'abaixo') ...[
              _linha('Ração do dia', '${_fmt(r.racaoDiariaKg)} kg',
                  destaque: true),
              _linha('Frequência', '${r.nTratos} trato(s)/dia'),
              _linha('Ração por trato', '${_fmt(r.racaoPorTratoKg)} kg'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bandejas(BuildContext context, RecomendacaoArracoamento r) {
    final pct = r.bandejaPct;
    if (pct == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bandeja de alimentação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _linha('Raça na bandeja',
                '${_fmt(pct)}% da ração do dia (${_fmt(r.racaoDiariaKg * pct / 100)} kg)'),
            _linha('Verificação', _tempo(r.bandejaTempoH ?? 0)),
          ],
        ),
      ),
    );
  }

  Widget _comoChegamos(BuildContext context, RecomendacaoArracoamento r) {
    final etapaTaxa = r.status == 'abaixo'
        ? 'Taxa: não é calculada — o peso está abaixo da tabela FAO.'
        : 'Taxa: interpolada entre os pontos FAO de ${_fmt(r.pesoMedio)} g.';
    return Card(
      child: ExpansionTile(
        title: const Text('Como chegamos a esse resultado?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '1. Biomassa = nº de vivos × peso ÷ 1000\n'
              '   = ${_fmt(r.nVivos.toDouble())} × ${_fmt(r.pesoMedio)} ÷ 1000 '
              '= ${_fmt(r.biomassaKg)} kg\n\n'
              '2. $etapaTaxa\n\n'
              '3. Ração do dia = biomassa × taxa ÷ 100\n'
              '   = ${_fmt(r.biomassaKg)} × ${_fmt(r.taxaPct ?? 0)} ÷ 100 '
              '= ${_fmt(r.racaoDiariaKg)} kg\n\n'
              '4. Ração por trato = ração do dia ÷ nº de tratos\n'
              '   = ${_fmt(r.racaoDiariaKg)} ÷ ${r.nTratos} '
              '= ${_fmt(r.racaoPorTratoKg)} kg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _fonte(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fonte e metodologia',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '${_especie.nome} (${_especie.nomeCientifico}), fase '
              '${_especie.fase}. Tabela de referência ${_especie.fonte}, '
              'válida para ${_fmt(_especie.pesoMin)} a '
              '${_fmt(_especie.pesoMax)} g, densidade de '
              '${_fmt(_especie.densidadeRefMin)}–'
              '${_fmt(_especie.densidadeRefMax)} PL/m² e FCA de '
              '${_fmt(_especie.fcrRefMin)}–${_fmt(_especie.fcrRefMax)}.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(rotulo)),
          Text(valor,
              style: destaque
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null),
        ],
      ),
    );
  }

  String _tempo(double horas) {
    final h = horas.floor();
    final min = ((horas - h) * 60).round();
    if (h <= 0) return '$min min';
    return '$h h $min min';
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
