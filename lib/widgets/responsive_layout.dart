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
        return ListView(
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
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
