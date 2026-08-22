import 'package:flutter/material.dart';

/// Um [Scaffold] cujas barras (barra de título de cima e/ou barra de navegação
/// de baixo) **somem ao rolar para baixo** e **voltam ao rolar para cima** —
/// comportamento comum em sites móveis, que faz o conteúdo ocupar a tela toda.
///
/// Detecta a direção do scroll no [body] (qualquer `ListView`/`CustomScrollView`
/// dentro dele emite [ScrollNotification]) e anima as barras para fora com
/// `AnimatedSlide`, enquanto o conteúdo expande com `AnimatedPadding`.
class ScrollHideScaffold extends StatefulWidget {
  /// Barra de título de cima (opcional). Pode ter `actions`.
  final PreferredSizeWidget? appBar;

  /// Barra de navegação de baixo (opcional), ex.: `NavigationBar`.
  final Widget? bottomBar;

  /// Altura da [bottomBar] usada para afastar o conteúdo enquanto visível.
  /// Padrão: altura padrão da `NavigationBar` do Material 3.
  final double bottomBarHeight;

  /// Conteúdo rolável da tela.
  final Widget body;

  /// Botão de ação flutuante (ex.: "Novo viveiro" no Home), posicionado acima
  /// da barra de baixo quando ela está visível.
  final Widget? floatingActionButton;

  /// A cor de fundo atrás das barras e do conteúdo (evita "fundo errado" nos
  /// espaços liberados quando as barras ocultam).
  final Color? backgroundColor;

  const ScrollHideScaffold({
    super.key,
    this.appBar,
    this.bottomBar,
    this.bottomBarHeight = 80,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  State<ScrollHideScaffold> createState() => _ScrollHideScaffoldState();
}

class _ScrollHideScaffoldState extends State<ScrollHideScaffold> {
  static const _dur = Duration(milliseconds: 200);
  static const _curve = Curves.easeOut;

  bool _show = true;
  double _ultimoPixels = 0;

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification ||
        n is ScrollEndNotification ||
        n is UserScrollNotification) {
      final m = n.metrics;
      final delta = m.pixels - _ultimoPixels;
      _ultimoPixels = m.pixels;

      if (m.pixels <= 0) {
        _setMostrar(true);
      } else if (delta > 3 && m.pixels > 120) {
        // Rolando para baixo (passou do limiar): oculta.
        _setMostrar(false);
      } else if (delta < -3) {
        // Rolando para cima: mostra.
        _setMostrar(true);
      }
    }
    return false;
  }

  void _setMostrar(bool v) {
    if (v != _show) setState(() => _show = v);
  }

  @override
  Widget build(BuildContext context) {
    final fundo = widget.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final appBarH = widget.appBar?.preferredSize.height ?? 0;
    final bottomH = widget.bottomBar == null ? 0.0 : widget.bottomBarHeight;
    final fab = widget.floatingActionButton;
    final fabH = fab == null ? 0.0 : 80.0;

    return ColoredBox(
      color: fundo,
      child: Stack(
        children: [
          // Corpo preenche a tela; o padding nas bordas se ajusta ao estado
          // das barras para o conteúdo expandir quando elas ocultam.
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SafeArea(
                top: widget.appBar == null,
                bottom: widget.bottomBar == null,
                child: AnimatedPadding(
                  duration: _dur,
                  curve: _curve,
                  padding: EdgeInsets.only(
                    top: _show ? appBarH : 0,
                    bottom: (_show ? bottomH : 0) + (fab != null ? fabH : 0),
                  ),
                  child: widget.body,
                ),
              ),
            ),
          ),
          // Botão de ação flutuante (acima da barra de baixo, quando visível).
          if (fab != null)
            Positioned(
              right: 16,
              bottom: (_show ? bottomH : 0) + 16,
              child: fab,
            ),
          // Barra de topo (desliza para fora quando ocultada).
          if (widget.appBar != null)
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedSlide(
                offset: _show ? Offset.zero : const Offset(0, -1),
                duration: _dur,
                curve: _curve,
                child: widget.appBar,
              ),
            ),
          // Barra de baixo (desliza para fora quando ocultada).
          if (widget.bottomBar != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSlide(
                offset: _show ? Offset.zero : const Offset(0, 1),
                duration: _dur,
                curve: _curve,
                child: widget.bottomBar,
              ),
            ),
        ],
      ),
    );
  }
}
