import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/crescimento.dart';
import '../domain/modelos.dart';
import '../state/app_state.dart';
import '../widgets/responsive_layout.dart';

/// Tela dedicada ao gráfico de crescimento: evolução do peso médio (g) ao
/// longo do tempo, por viveiro, mais um resumo das métricas do ciclo.
class CrescimentoScreen extends StatefulWidget {
  final String? viveiroId;
  const CrescimentoScreen({super.key, this.viveiroId});

  @override
  State<CrescimentoScreen> createState() => _CrescimentoScreenState();
}

class _CrescimentoScreenState extends State<CrescimentoScreen> {
  String? _viveiroId;

  @override
  void initState() {
    super.initState();
    _viveiroId = widget.viveiroId;
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  String _data(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}/${p2(d.month)}/${d.year}';
  }

  String _dataCurta(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}/${p2(d.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vivo = _viveiroId == null ? null : state.porId(_viveiroId);
    final biometrias =
        vivo == null ? const <Biometria>[] : state.listarBiometrias(vivo.id);
    final cron = biometriasCronologicas(biometrias);
    final resumo = resumirCrescimento(cron);

    return Scaffold(
      appBar: AppBar(title: const Text('Crescimento')),
      body: ResponsiveListView(
        children: [
          if (state.viveiros.isNotEmpty) ...[
            _seletorViveiro(state),
            const SizedBox(height: 12),
          ],
          if (vivo == null)
            const _SemViveiro()
          else if (cron.isEmpty)
            _Vazio(vivo.nome)
          else ...[
            _cardGrafico(cron),
            const SizedBox(height: 12),
            if (resumo != null) ...[
              _cardResumo(resumo),
              const SizedBox(height: 12),
            ] else
              const _PoucosDados(),
            const SizedBox(height: 12),
            _cardNota(vivo),
          ],
        ],
      ),
    );
  }

  Widget _seletorViveiro(AppState state) {
    return DropdownButtonFormField<String>(
      value: _viveiroId ?? '',
      decoration: const InputDecoration(
        labelText: 'Viveiro',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.water),
      ),
      items: [
        const DropdownMenuItem<String>(value: '', child: Text('Selecionar…')),
        ...state.viveiros.map(
          (v) => DropdownMenuItem<String>(value: v.id, child: Text(v.nome)),
        ),
      ],
      onChanged: (id) => setState(() {
        _viveiroId = (id == null || id.isEmpty) ? null : id;
      }),
    );
  }

  Widget _cardGrafico(List<Biometria> cron) {
    final primeiro = cron.first.data;
    final spots = <FlSpot>[
      for (final b in cron)
        FlSpot(
          b.data.difference(primeiro).inHours / 24.0,
          b.pesoMedio,
        ),
    ];
    final cor = Theme.of(context).colorScheme.primary;
    final corFundo = Theme.of(context).colorScheme.primaryContainer;
    final corTexto = Theme.of(context).colorScheme.onPrimaryContainer;

    return Card(
      color: corFundo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Peso médio do camarão (g)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Evolução ao longo das amostragens',
                style: TextStyle(color: corTexto.withOpacity(0.7))),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: spots.length > 1 ? spots.last.x : spots.first.x + 1,
                  minY: _minY(spots),
                  maxY: _maxY(spots),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: corTexto.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, meta) => Text(
                          _fmt(v),
                          style: TextStyle(color: corTexto.withOpacity(0.7)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: spots.length > 4
                            ? (spots.length / 4).ceilToDouble()
                            : 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if (i < 0 || i >= cron.length) {
                            return const SizedBox();
                          }
                          return Text(
                            _dataCurta(cron[i].data),
                            style: TextStyle(
                                color: corTexto.withOpacity(0.7), fontSize: 11),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => touched.map((t) {
                        final i = t.x.round();
                        final data =
                            i >= 0 && i < cron.length ? cron[i].data : null;
                        final dataTxt = data == null ? '' : ' · ${_data(data)}';
                        return LineTooltipItem(
                          '${_fmt(t.y)} g$dataTxt',
                          TextStyle(
                            color: corTexto,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: cor,
                      barWidth: 3,
                      isCurved: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cor.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _minY(List<FlSpot> spots) {
    final min = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final f = min.floorToDouble();
    return f - (min == f ? 0 : 0.5);
  }

  double _maxY(List<FlSpot> spots) {
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return max.ceilToDouble() + 0.5;
  }

  Widget _cardResumo(ResumoCrescimento r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo do ciclo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _linha('Amostragens', '${r.nAmostras}'),
            _linha('Peso inicial', '${_fmt(r.pesoInicial)} g'),
            _linha('Peso atual', '${_fmt(r.pesoFinal)} g'),
            _linha('Ganho total',
                '${_fmt(r.ganhoTotal)} g (${r.ganhoTotal >= 0 ? '+' : ''}${_fmt(r.ganhoTotal)})'),
            _linha('Acompanhado por', '${r.dias} dia(s)'),
            _linha('Ganho médio', '${_fmt(r.ganhoDiarioMedio)} g/dia'),
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _cardNota(Viveiro v) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡 Como usar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Toque no gráfico pra ver o peso e a data de cada amostragem. '
              'Compare o ganho médio (g/dia) com o esperado pra fase do ciclo '
              'de ${v.nome}. Amostragens regulares (semanais) dão uma curva '
              'mais confiável.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SemViveiro extends StatelessWidget {
  const _SemViveiro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Text('Escolha um viveiro pra ver o crescimento.'),
    );
  }
}

class _Vazio extends StatelessWidget {
  final String nome;
  const _Vazio(this.nome);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.show_chart, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Sem biometrias em "$nome".',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Cadastre amostragens pra acompanhar o crescimento.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PoucosDados extends StatelessWidget {
  const _PoucosDados();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Adicione mais amostragens pra ver a curva de crescimento. '
          'Com 1 ponto ainda não dá pra calcular ganho.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
