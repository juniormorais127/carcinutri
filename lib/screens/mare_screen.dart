import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mare_api.dart';
import '../db/repositories.dart';
import '../domain/mare.dart';
import '../state/app_state.dart';

/// Aba Maré: horários de preamar/baixa-mar do dia + gráfico da altura da maré.
///
/// Fonte principal: Tábua de Maré API (dados reais por porto), cacheada
/// localmente para funcionar offline e respeitar a cota (1 req/mês por porto).
/// Sem dados reais, cai no modelo senoidal manual (fallback offline).
class MareScreen extends StatefulWidget {
  const MareScreen({super.key});

  @override
  State<MareScreen> createState() => _MareScreenState();
}

class _MareScreenState extends State<MareScreen> {
  final MareApi _api = MareApi();

  // --- Campos do modelo manual (fallback) ---
  final _amplitude = TextEditingController(text: '2.0');
  final _nivelMedio = TextEditingController(text: '0');
  final _horaPreamar = TextEditingController(text: '06:00');
  TipoMare _tipo = TipoMare.semidiurna;
  ResumoMare? _resumo;

  // --- Maré real ---
  List<String> _estados = [];
  List<PortoMare> _portos = [];
  String _estado = 'ce';
  String? _portoId; // null até carregar portos
  bool _buscando = false;
  bool _temRepo = false;
  bool _initDone = false;
  final Set<String> _tentativas = {};
  Map<int, DiaMareApi>? _tabua;
  String? _erro;
  DateTime? _salvoEm;
  String _fonte = 'offline';

  static final _horaRe = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

  @override
  void initState() {
    super.initState();
    // Modelo manual de partida (valores padrão já válidos).
    _resumo = calcularMare(
      data: DateTime.now(),
      amplitudeM: 2.0,
      nivelMedioM: 0,
      tipo: TipoMare.semidiurna,
      horaPreamar: const Duration(hours: 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initDone) return;
    _initDone = true;
    // O AppState (com o banco) só existe no app real; em testes/isolado,
    // ausente → a aba opera só no modo manual, sem rede.
    try {
      context.read<AppState>();
      _temRepo = true;
    } catch (_) {
      return;
    }
    _carregarEstadosPortos();
  }

  @override
  void dispose() {
    _amplitude.dispose();
    _nivelMedio.dispose();
    _horaPreamar.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

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

  // ---------------------------------------------------- carregar maré real

  Future<void> _carregarEstadosPortos() async {
    final repo = context.read<AppState>().mareRepo;

    // Estados (cache → rede).
    final cE = await repo.ler('mare|estados');
    if (cE != null) {
      _estados = (cE['data'] as List).cast<String>();
    } else {
      try {
        _estados = await _api.estados();
        await repo.salvar('mare|estados', {'data': _estados});
      } catch (_) {/* mantém vazio; cai no modelo manual */}
    }

    await _carregarPortos(repo, _estado);
    if (_portoId != null) await _carregarMare();
  }

  Future<void> _carregarPortos(MareRepositorio repo, String estado) async {
    final cP = await repo.ler('mare|portos|$estado');
    if (cP != null) {
      _portos = (cP['data'] as List)
          .map((e) => PortoMare(
              id: (e as Map)['id'] as String, nome: e['nome'] as String))
          .toList();
    } else {
      try {
        _portos = await _api.portos(estado);
        await repo.salvar('mare|portos|$estado', {
          'data': [
            for (final p in _portos) {'id': p.id, 'nome': p.nome}
          ]
        });
      } catch (_) {
        _portos = [];
      }
    }
    if (_portos.isNotEmpty && !_portos.any((p) => p.id == _portoId)) {
      _portoId = _portos.first.id;
    }
  }

  Future<void> _carregarMare({bool forcar = false}) async {
    final repo = context.read<AppState>().mareRepo;
    final id = _portoId;
    if (id == null) return;
    final agora = DateTime.now();
    final ano = agora.year, mes = agora.month;
    final chave = 'mare|$id|$ano-$mes';
    final tentativa = 'tentativa|$id|$ano-$mes';
    final temCache = await repo.ler(chave) != null;
    final jaTentou = _tentativas.contains(tentativa);

    if (temCache && !forcar) {
      await _usarCache(repo, chave, ano, mes);
      return;
    }
    if (!forcar && jaTentou) {
      await _usarCacheOuManual(repo, chave, ano, mes);
      return;
    }

    _tentativas.add(tentativa);
    setState(() => _buscando = true);
    try {
      final r = await _api.tabuaMes(id, ano, mes);
      await repo.salvar(chave, {
        'salvoEm': agora.toIso8601String(),
        'json': r.raw,
      });
      if (!mounted) return;
      setState(() {
        _tabua = r.dias;
        _salvoEm = agora;
        _fonte = 'online';
        _erro = null;
        _buscando = false;
      });
    } catch (_) {
      if (!mounted) return;
      await _usarCacheOuManual(repo, chave, ano, mes);
      setState(() {
        _erro =
            'Não foi possível buscar a maré real. Usando dados salvos ou o '
            'modelo manual abaixo.';
        _buscando = false;
      });
    }
  }

  Future<void> _usarCache(
      MareRepositorio repo, String chave, int ano, int mes) async {
    final c = await repo.ler(chave);
    if (c == null) return;
    final raw = Map<String, dynamic>.from(c['json'] as Map);
    final dias = parseTabua(raw, ano, mes);
    if (!mounted) return;
    setState(() {
      _tabua = dias;
      _salvoEm = DateTime.tryParse(c['salvoEm'] as String? ?? '');
      _fonte = 'cache';
      _erro = null;
    });
  }

  Future<void> _usarCacheOuManual(
      MareRepositorio repo, String chave, int ano, int mes) async {
    final c = await repo.ler(chave);
    if (c != null) {
      await _usarCache(repo, chave, ano, mes);
    }
  }

  // --------------------------------------------------- modelo manual

  void _calcularManual() {
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
    final inicial = TimeOfDay(
        hour: atual?.inHours ?? 6, minute: (atual?.inMinutes ?? 0) % 60);
    final t = await showTimePicker(context: context, initialTime: inicial);
    if (t != null) {
      _horaPreamar.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      _calcularManual();
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final temReal = _temRepo;
    return Scaffold(
      appBar: AppBar(title: const Text('Maré')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (temReal) ...[
            _cardReal(),
            const SizedBox(height: 16),
          ] else
            _semBancoAviso(),
          ..._conteudo(),
        ],
      ),
    );
  }

  Widget _semBancoAviso() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.cloud_off),
        title: Text('Modo offline'),
        subtitle: Text(
            'Sem acesso ao banco local — mostrando o modelo manual de maré.'),
      ),
    );
  }

  // Card principal: maré real por porto.
  Widget _cardReal() {
    final portos = _portos;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maré real · Tábua de Maré',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Dados de preamar/baixa-mar dos portos brasileiros, atualizados '
              'pela DHN. Buscado e salvo localmente (1 vez/mês por porto).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      for (final e in _estados)
                        DropdownMenuItem(
                            value: e, child: Text(e.toUpperCase())),
                    ],
                    onChanged: _estados.isEmpty
                        ? null
                        : (e) {
                            if (e == null) return;
                            setState(() => _estado = e);
                            _carregarPortos(
                                context.read<AppState>().mareRepo, e);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _portoId,
                    decoration: const InputDecoration(labelText: 'Porto'),
                    items: [
                      for (final p in portos)
                        DropdownMenuItem(value: p.id, child: Text(p.nome)),
                    ],
                    onChanged: portos.isEmpty
                        ? null
                        : (id) {
                            if (id == null) return;
                            setState(() => _portoId = id);
                            _carregarMare(forcar: true);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (_buscando || _portoId == null) ? null : _carregarMare,
                    icon: _buscando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Buscar marés do mês'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _linhaStatus(),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(_erro!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linhaStatus() {
    final fonte = _fonte;
    final salvo = _salvoEm;
    final texto = switch (fonte) {
      'online' => 'Fonte: online · atualizado ${_hora(salvo!)}',
      'cache' => 'Fonte: salvo (offline) · '
          'atualizado ${salvo == null ? '—' : _hora(salvo)}',
      _ => 'Fonte: modelo manual abaixo (sem dados reais salvos)',
    };
    return Row(
      children: [
        Icon(
          fonte == 'offline' ? Icons.cloud_off : Icons.cloud_done,
          size: 16,
          color: fonte == 'offline'
              ? Colors.orange
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  // Corpo: maré real do dia (se houver) + modelo manual (fallback).
  List<Widget> _conteudo() {
    final dia = _tabua?[DateTime.now().day];
    if (dia != null) {
      return [
        _cardProximaReal(dia),
        const SizedBox(height: 12),
        _cardEventosReal(dia),
        const SizedBox(height: 12),
        _cardGraficoReal(dia),
      ];
    }
    final resumo = _resumo;
    return [
      Text(
        'Horários de preamar e baixa-mar calculados offline, a partir da '
        'amplitude e do horário da preamar da sua região.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      _campos(),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _calcularManual,
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
    ];
  }

  // ------------------------------------------------------- cards (maré real)

  Widget _cardProximaReal(DiaMareApi dia) {
    final agora = DateTime.now();
    EventoRealMare? prox;
    for (final e in dia.eventos) {
      if (e.tempo.isAfter(agora)) {
        prox = e;
        break;
      }
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.waves, size: 32, color: Colors.blue),
        title: Text(prox == null
            ? 'Sem marés restantes hoje'
            : 'Próxima maré: ${prox.preamar ? 'Preamar' : 'Baixa-mar'}'),
        subtitle: Text(prox == null
            ? 'Confira os horários abaixo.'
            : '${_hora(prox.tempo)} · ${_fmt(prox.nivelM)} m'),
      ),
    );
  }

  Widget _cardEventosReal(DiaMareApi dia) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marés de hoje (porto)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final e in dia.eventos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(e.preamar ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                        color: e.preamar ? Colors.orange : Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.preamar ? 'Preamar' : 'Baixa-mar')),
                    Text('${_hora(e.tempo)} · ${_fmt(e.nivelM)} m',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardGraficoReal(DiaMareApi dia) {
    final cor = Theme.of(context).colorScheme.primary;
    final corFundo = Theme.of(context).colorScheme.primaryContainer;
    final corTexto = Theme.of(context).colorScheme.onPrimaryContainer;
    final spots = <FlSpot>[
      for (final n in dia.niveis)
        FlSpot(
          n.tempo.difference(dia.dia).inMinutes / 60.0,
          n.nivelM,
        ),
    ];
    if (spots.length == 1) spots.add(FlSpot(spots.first.x, spots.first.y));
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
            Text('Dados do porto selecionado.',
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

  // ------------------------------------------------- cards (modelo manual)

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
                onChanged: (_) => _calcularManual(),
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
                onChanged: (_) => _calcularManual(),
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
                onChanged: (_) => _calcularManual(),
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
            _calcularManual();
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
