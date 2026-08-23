import 'package:flutter/material.dart';

/// Assinatura visual global do AQUACENSO.
///
/// Fica acima das rotas para também alcançar telas empilhadas, mas não recebe
/// eventos nem participa da árvore de acessibilidade.
class BrandWatermarkLayer extends StatelessWidget {
  final Widget child;

  const BrandWatermarkLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final mostrarNome = constraints.maxWidth >= 520;
        final cores = Theme.of(context).colorScheme;

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              right: desktop ? 28 : 18,
              bottom: desktop ? 22 : 84,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.065,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 46,
                          color: cores.secondary,
                        ),
                        if (mostrarNome) ...[
                          const SizedBox(width: 7),
                          Text(
                            'AQUACENSO',
                            style: TextStyle(
                              color: cores.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
