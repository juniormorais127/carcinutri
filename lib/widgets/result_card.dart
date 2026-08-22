import 'package:flutter/material.dart';

import '../domain/calculadoras.dart';

/// Cartão que exibe os resultados de um cálculo, com o item principal destacado.
class ResultCard extends StatelessWidget {
  final ResultadoCalculo resultado;

  const ResultCard({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in resultado.itens) _linha(context, item),
          ],
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, ItemResultado item) {
    final colorScheme = Theme.of(context).colorScheme;
    final estiloDestaque = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        );
    final estiloNormal = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              item.rotulo,
              style: item.destaque ? estiloDestaque : estiloNormal,
            ),
          ),
          Text(
            item.valor,
            style: item.destaque
                ? estiloDestaque
                : estiloNormal?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
