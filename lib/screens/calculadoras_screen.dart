import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/calculadoras.dart';
import '../widgets/responsive_layout.dart';

class CalculadorasScreen extends StatelessWidget {
  const CalculadorasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadoras')),
      body: ResponsiveListView(
        children: [
          _bannerRecomendacao(context),
          const SizedBox(height: 24),
          Text('Ferramentas',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth;
              final colunas = largura >= 960
                  ? 4
                  : largura >= 680
                      ? 3
                      : largura >= 420
                          ? 2
                          : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: colunas,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 164,
                ),
                itemCount: todasCalculadoras.length,
                itemBuilder: (context, i) {
                  final d = todasCalculadoras[i];
                  return _card(context, d);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bannerRecomendacao(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: cores.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/arracoamento-recomendado'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cores.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.restaurant_rounded,
                    color: cores.onPrimary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recomendação de arraçoamento',
                      style: TextStyle(
                          color: cores.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Camarão-branco-do-Pacífico · base FAO. Quanto '
                      'fornecer hoje, em quantos tratos e como usar a bandeja.',
                      style: TextStyle(
                          color: cores.onPrimaryContainer.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cores.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, DefinicaoCalculadora d) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/calculadora/${d.tipo.name}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(d.icone, style: const TextStyle(fontSize: 22)),
              ),
              const Spacer(),
              Text(d.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                d.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
