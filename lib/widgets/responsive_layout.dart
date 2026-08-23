import 'package:flutter/material.dart';

/// Lista rolável centralizada, com respiro adaptativo e largura confortável
/// para leitura tanto no celular quanto na web.
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.maxWidth = 1040,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 720 ? 32.0 : 16.0;
        return _TechBackground(
          child: ListView(
            padding:
                padding ?? EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Centraliza conteúdo não rolável e mantém margens consistentes na web.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 1040,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 720 ? 32.0 : 16.0;
        return _TechBackground(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: padding ??
                    EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TechBackground extends StatelessWidget {
  final Widget child;

  const _TechBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF1FAF6), Color(0xFFF5F7FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -90,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primary.withOpacity(0.12), primary.withOpacity(0)],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _TechGridPainter())),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _TechGridPainter extends CustomPainter {
  const _TechGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF0F766E).withOpacity(0.035)
      ..strokeWidth = 1;
    const passo = 40.0;

    for (var x = 0.0; x <= size.width; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y <= size.height; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final dotPaint = Paint()..color = const Color(0xFF16A34A).withOpacity(0.1);
    for (var x = 0.0; x <= size.width; x += passo) {
      for (var y = 0.0; y <= size.height; y += passo) {
        canvas.drawCircle(Offset(x, y), 1.25, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
