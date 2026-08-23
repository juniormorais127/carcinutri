import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/mare.dart';

/// Aba Maré: horários de preamar/baixa-mar do dia + gráfico da altura da maré,
/// calculados offline a partir da amplitude e do horário da preamar informados.
class MareScreen extends StatefulWidget {
  const MareScreen({super.key});

  @override
  State<MareScreen> createState() => _MareScreenState();
}

class _MareScreenState extends State<MareScreen> {
  final _amplitude = TextEditingController(text: '2.0');
  final _nivelMedio = TextEditingController(text: '0');
  final _horaPreamar = TextEditingController(text: '06:00');
  TipoMare _tipo = TipoMare.semidiurna;
  ResumoMare? _resumo;

  static final _horaRe = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

  @override
  void initState() {
    super.initState();
    // Cálculo inicial com os valores padrão (já válidos): sem snackbar/setState,
    // pois ainda não há build. Os demais cálculos vêm de ações do usuário.
    _resumo = calcularMare(
      data: DateTime.now(),
      amplitudeM: 2.0,
      nivelMedioM: 0,
      tipo: TipoMare.semidiurna,
      horaPreamar: const Duration(hours: 6),
    );
  }

  @override
  void dispose() {
    _amplitude.dispose();
    _nivelMedio.dispose();
    _horaPreamar.dispose();
    super.dispose();
  }

  Duration? _parseHora(String t) {
    final m = _horaRe.firstMatch(t.trim());
    if (m == null) return null;
    return Duration(
        hours: int.parse(m.group(1)!), minutes: int.parse(m.group(2)!));
  }

  double? _parseNum(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  void _calcular() {
    final messenger = ScaffoldMessenger.of(context);
    final amp = _parseNum(_amplitude);
    if (amp == null || amp <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Informe a amplitude da maré (m).')));
      return;
    }
    final nivel = _parseNum(_nivelMedio) ?? 0;
    final hora = _parseHora(_horaPreamar.text);
    if (hora == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Informe o horário da preamar no formato HH:mm.')));
      return;
    }
    setState(() {
      _resumo = calcularMare(
        data: DateTime.now(),
        amplitudeM: amp,
        nivelMedioM: nivel,
        tipo: _tipo,
        horaPreamar: hora,
      );
    });
  }

  Future<void> _escolherHora() async {
    final atual = _parseHora(_horaPreamar.text);
    final inicial =
        TimeOfDay(hour: atual?.inHours ?? 6, minute: (atual?.inMinutes ?? 0) % 60);
    final t = await showTimePicker(context: context, initialTime: inicial);
    if (t != null) {
      _horaPreamar.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      _calcular();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumo = _resumo;
    return Scaffold(
      appBar: AppBar(title: const Text('Maré')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Horários de preamar e baixa-mar calculados offline, a partir da '
            'amplitude e do horário da preamar da sua região.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _campos(),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.update),
            label: const Text('Atualizar maré de hoje'),
          ),
          if (resumo != null) ...[
            const SizedBox(height: 16),
            _cardProxima(resumo),
            const SizedBox(height: 12),
            _cardEventos(resumo),
            const SizedBox(height: 12),
            _cardGrafico(resumo),
          ],
        ],
      ),
    );
  }

  Widget _campos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amplitude,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amplitude da maré',
                  suffixText: 'm',
                ),
                onChanged: (_) => _calcular(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nivelMedio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Nível médio',
                  suffixText: 'm',
                ),
                onChanged: (_) => _calcular(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _horaPreamar,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Horário da preamar',
                  suffixText: 'HH:mm',
                ),
                onChanged: (_) => _calcular(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Escolher horário',
              onPressed: _escolherHora,
              icon: const Icon(Icons.schedule),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TipoMare>(
          value: _tipo,
          decoration: const InputDecoration(labelText: 'Tipo de maré'),
          items: [
            for (final t in TipoMare.values)
              DropdownMenuItem(value: t, child: Text(t.rotulo)),
          ],
          onChanged: (t) {
            if (t == null) return;
            setState(() => _tipo = t);
            _calcular();
          },
        ),
      ],
    );
  }

  Widget _cardProxima(ResumoMare r) {
    final prox = r.proximoEvento(DateTime.now());
    return Card(
      child: ListTile(
        leading: const Icon(Icons.waves, size: 32, color: Colors.blue),
        title: Text(prox == null
            ? 'Sem marés restantes hoje'
            : 'Próxima maré: ${prox.tipo.curto}'),
        subtitle: Text(prox == null
            ? 'Confira o horário de amanhã nas marés de hoje/manhã.'
            : '${_hora(prox.tempo)} · ${_fmt(prox.alturaM)} m'),
      ),
    );
  }

  Widget _cardEventos(ResumoMare r) {
    final hoje = r.eventosDeHoje;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marés de hoje',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (hoje.isEmpty)
              const Text('Nenhum evento dentro de hoje.'),
            for (final e in hoje)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(e.tipo.ehPreamar ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                        color: e.tipo.ehPreamar ? Colors.orange : Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.tipo.curto)),
                    Text('${_hora(e.tempo)} · ${_fmt(e.alturaM)} m',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardGrafico(ResumoMare r) {
    final cor = Theme.of(context).colorScheme.primary;
    final corFundo = Theme.of(context).colorScheme.primaryContainer;
    final corTexto = Theme.of(context).colorScheme.onPrimaryContainer;
    final spots = <FlSpot>[
      for (final p in r.curva)
        FlSpot(
          p.tempo.difference(r.data).inMinutes / 60.0,
          p.alturaM,
        ),
    ];
    return Card(
      color: corFundo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Altura da maré hoje (m)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Modelo semidiurna/diurna de referência.',
                style: TextStyle(color: corTexto.withOpacity(0.7))),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 24,
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
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
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
                        interval: 6,
                        getTitlesWidget: (v, meta) => Text(
                          '${v.toInt()}h',
                          style: TextStyle(
                              color: corTexto.withOpacity(0.7), fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => touched.map((t) {
                        return LineTooltipItem(
                          '${t.y.toStringAsFixed(1)} m às ${(t.x ~/ 1).toString().padLeft(2, '0')}:${((t.x % 1) * 60).round().toString().padLeft(2, '0')}',
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
                      dotData: const FlDotData(show: false),
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

  String _hora(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.hour)}:${p2(d.minute)}';
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}
