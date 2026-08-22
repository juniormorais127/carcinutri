import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/calculadoras.dart';
import '../widgets/scroll_hide_scaffold.dart';

class CalculadorasScreen extends StatelessWidget {
  const CalculadorasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollHideScaffold(
      appBar: AppBar(title: const Text('Calculadoras')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _bannerRecomendacao(context),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: todasCalculadoras.length,
            itemBuilder: (context, i) {
              final d = todasCalculadoras[i];
              return _card(context, d);
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
              const Text('🍽️', style: TextStyle(fontSize: 32)),
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
                          color:
                              cores.onPrimaryContainer.withOpacity(0.85)),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.icone, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(d.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
