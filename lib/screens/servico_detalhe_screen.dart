import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../state/auth_state.dart';
import '../state/servicos_state.dart';
import '../widgets/responsive_layout.dart';

class ServicoDetalheScreen extends StatefulWidget {
  final String id;
  const ServicoDetalheScreen({super.key, required this.id});

  @override
  State<ServicoDetalheScreen> createState() => _ServicoDetalheScreenState();
}

class _ServicoDetalheScreenState extends State<ServicoDetalheScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valor;
  late final TextEditingController _mensagem;

  SolicitacaoServico? _servico;
  PropostaServico? _minhaProposta;
  bool _carregando = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _valor = TextEditingController();
    _mensagem = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _valor.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final mercado = context.read<MercadoState>();
      final auth = context.read<AuthState>();
      final s = await mercado.obterServico(widget.id);
      final propostas = await mercado.listarPropostas(widget.id);

      PropostaServico? minha;
      final userId = auth.usuario?.id;
      if (userId != null) {
        for (final p in propostas) {
          if (p.tecnicoId == userId) {
            minha = p;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _servico = s;
          _minhaProposta = minha;
          if (minha != null) {
            _valor.text = minha.valor.toStringAsFixed(2);
            _mensagem.text = minha.mensagem ?? '';
          } else {
            _valor.text = s.valorEstimado.toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviarProposta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final valor = double.parse(_valor.text.trim().replaceAll(',', '.'));
      final msg = _mensagem.text.trim().isEmpty ? null : _mensagem.text.trim();
      final mercado = context.read<MercadoState>();
      await mercado.criarProposta(widget.id, valor: valor, mensagem: msg);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposta enviada com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _carregarDados();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar proposta: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Serviço')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null || _servico == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Serviço')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cores.error),
                const SizedBox(height: 12),
                Text(_erro ?? 'Serviço não encontrado.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _carregarDados, child: const Text('Tentar Novamente')),
              ],
            ),
          ),
        ),
      );
    }

    final s = _servico!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Oportunidade'),
      ),
      body: ResponsiveListView(
        children: [
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cores.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Aberto',
                          style: TextStyle(
                            color: cores.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (s.produtorNome.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: cores.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Solicitante: ${s.produtorNome}',
                          style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  if (s.categoria != null || s.cidade != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (s.categoria != null)
                          Chip(
                            label: Text(s.categoria!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.cidade != null)
                          Chip(
                            avatar: const Icon(Icons.location_on_outlined, size: 16),
                            label: Text(s.cidade!),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Valor Estimado pelo Produtor:',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                      Text(
                        'R\$ ${s.valorEstimado.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: cores.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (s.descricao != null && s.descricao!.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(
                      'Descrição:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: cores.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.descricao!,
                      style: TextStyle(color: cores.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_minhaProposta != null) ...[
            Text(
              'Sua Proposta Enviada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              color: cores.surfaceVariant.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor Oferecido:',
                          style: TextStyle(color: cores.onSurfaceVariant),
                        ),
                        Text(
                          'R\$ ${_minhaProposta!.valor.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cores.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_minhaProposta!.mensagem != null && _minhaProposta!.mensagem!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Mensagem: ${_minhaProposta!.mensagem!}',
                        style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _minhaProposta!.status == 'pendente'
                              ? Icons.hourglass_top_rounded
                              : _minhaProposta!.status == 'aceita'
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_outlined,
                          size: 16,
                          color: _minhaProposta!.status == 'aceita'
                              ? cores.primary
                              : _minhaProposta!.status == 'pendente'
                                  ? Colors.orange
                                  : cores.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Status: ${_minhaProposta!.status.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _minhaProposta!.status == 'aceita'
                                ? cores.primary
                                : _minhaProposta!.status == 'pendente'
                                    ? Colors.orange
                                    : cores.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Deseja atualizar sua proposta?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'Enviar Contraproposta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _valor,
                      decoration: const InputDecoration(
                        labelText: 'Valor da sua proposta (R\$) *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (val == null || val <= 0) {
                          return 'Informe um valor válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mensagem,
                      decoration: const InputDecoration(
                        labelText: 'Mensagem explicativa (opcional)',
                        hintText: 'Ex.: Posso realizar o serviço amanhã. Equipamentos inclusos.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _enviando ? null : _enviarProposta,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_enviando ? 'Enviando...' : (_minhaProposta != null ? 'Atualizar Proposta' : 'Enviar Proposta')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
