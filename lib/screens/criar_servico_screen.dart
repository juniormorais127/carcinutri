import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/servico.dart';
import '../state/app_state.dart';
import '../state/sync_service.dart';
import '../widgets/responsive_layout.dart';

class CriarServicoScreen extends StatefulWidget {
  const CriarServicoScreen({super.key});

  @override
  State<CriarServicoScreen> createState() => _CriarServicoScreenState();
}

class _CriarServicoScreenState extends State<CriarServicoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;
  late final TextEditingController _cidade;
  late final TextEditingController _valor;
  String? _categoria = 'Manutenção';
  bool _salvando = false;

  final _categorias = const [
    'Manutenção',
    'Instalação',
    'Consultoria Técnica',
    'Análise de Água',
    'Povoamento / Despesca',
    'Manejo e Arraçoamento',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController();
    _descricao = TextEditingController();
    _cidade = TextEditingController();
    _valor = TextEditingController();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _cidade.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final valorEstimado = double.parse(_valor.text.trim().replaceAll(',', '.'));
      final s = SolicitacaoServico(
        id: gerarUuidV4(),
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        categoria: _categoria,
        cidade: _cidade.text.trim().isEmpty ? null : _cidade.text.trim(),
        valorEstimado: valorEstimado,
        status: 'aberto',
        criadoEm: DateTime.now(),
        sincronizado: false,
      );

      final app = context.read<AppState>();
      await app.salvarSolicitacao(s);

      if (mounted) {
        // Dispara sync em segundo plano se houver conexão
        context.read<SyncService>().sincronizar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação criada com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Solicitação de Serviço'),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveListView(
          children: [
            const SizedBox(height: 12),
            Card(
              color: cores.surfaceVariant.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cores.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Descreva o serviço necessário. Técnicos credenciados poderão visualizar e enviar contrapropostas.',
                        style: TextStyle(fontSize: 13, color: cores.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título do serviço *',
                hintText: 'Ex.: Manutenção no sistema de bombeamento',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return 'Informe um título com pelo menos 3 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cidade,
              decoration: const InputDecoration(
                labelText: 'Cidade / Região',
                hintText: 'Ex.: Aracati - CE',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valor,
              decoration: const InputDecoration(
                labelText: 'Valor Estimado (R\$) *',
                hintText: '0,00',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (val == null || val <= 0) {
                  return 'Informe um valor estimado válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(
                labelText: 'Descrição detalhada (opcional)',
                hintText: 'Detalhe o problema, viveiro, necessidades específicas, prazo esperado...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_salvando ? 'Salvando...' : 'Publicar Solicitação'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
