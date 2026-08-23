import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/arracoamento_recomendado_screen.dart';
import 'screens/biometria_form_screen.dart';
import 'screens/calculo_screen.dart';
import 'screens/calculadoras_screen.dart';
import 'screens/crescimento_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mare_screen.dart';
import 'screens/projecao_screen.dart';
import 'screens/viveiro_form_screen.dart';
import 'screens/viveiro_painel_screen.dart';
import 'state/app_state.dart';

final GoRouter _router = GoRouter(
  routes: [
    // Abas principais (rodapé): Início, Projeção e Maré.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/projecao', builder: (_, __) => const ProjecaoScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/mare', builder: (_, __) => const MareScreen()),
          ],
        ),
      ],
    ),
    // Telas empilhadas (abrem em tela cheia sobre as abas).
    GoRoute(
        path: '/calculadoras', builder: (_, __) => const CalculadorasScreen()),
    GoRoute(
        path: '/arracoamento-recomendado',
        builder: (_, __) => const ArracoamentoRecomendadoScreen()),
    GoRoute(
        path: '/calculadora/:tipo',
        builder: (_, s) => CalculoScreen(
              tipo: s.pathParameters['tipo']!,
              viveiroId: s.uri.queryParameters['viveiro'],
            )),
    GoRoute(
        path: '/crescimento', builder: (_, __) => const CrescimentoScreen()),
    GoRoute(
        path: '/crescimento/:id',
        builder: (_, s) =>
            CrescimentoScreen(viveiroId: s.pathParameters['id'])),
    GoRoute(path: '/viveiro', builder: (_, __) => const ViveiroFormScreen()),
    GoRoute(
        path: '/viveiro/:id',
        builder: (_, s) => ViveiroFormScreen(id: s.pathParameters['id'])),
    GoRoute(
        path: '/painel/:id',
        builder: (_, s) => ViveiroPainelScreen(id: s.pathParameters['id']!)),
    GoRoute(
        path: '/biometria/:viveiroId',
        builder: (_, s) =>
            BiometriaFormScreen(viveiroId: s.pathParameters['viveiroId'])),
    GoRoute(
        path: '/biometria', builder: (_, __) => const BiometriaFormScreen()),
    GoRoute(path: '/historico', builder: (_, __) => const HistoricoScreen()),
    GoRoute(
        path: '/historico/:id',
        builder: (_, s) => HistoricoScreen(id: s.pathParameters['id'])),
  ],
);

/// Casca das abas: corpo = branch ativa + barra de navegação no rodapé.
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usarRail = constraints.maxWidth >= 900;
        if (usarRail) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _irParaAba,
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Início'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month_rounded),
                        label: Text('Projeção'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.waves_outlined),
                        selectedIcon: Icon(Icons.waves_rounded),
                        label: Text('Maré'),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _irParaAba,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Projeção',
              ),
              NavigationDestination(
                icon: Icon(Icons.waves_outlined),
                selectedIcon: Icon(Icons.waves_rounded),
                label: 'Maré',
              ),
            ],
          ),
        );
      },
    );
  }

  void _irParaAba(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
}

final ThemeData _tema = _criarTema();

ThemeData _criarTema() {
  const verde = Color(0xFF16A34A);
  final cores = ColorScheme.fromSeed(
    seedColor: verde,
    brightness: Brightness.light,
    surface: const Color(0xFFF8FAF8),
  );
  final base = ThemeData(colorScheme: cores, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF4F7F4),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: const Color(0xFFF4F7F4),
      foregroundColor: cores.onSurface,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: cores.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cores.outlineVariant.withOpacity(0.7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cores.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cores.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cores.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 2,
      backgroundColor: Colors.white,
      indicatorColor: cores.primaryContainer,
      labelTextStyle: MaterialStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(MaterialState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: cores.primaryContainer,
      minWidth: 88,
      selectedLabelTextStyle: TextStyle(
        color: cores.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: cores.outlineVariant),
  );
}

class CarciniApp extends StatelessWidget {
  final AppState state;
  const CarciniApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp.router(
        title: 'AQUACENSO',
        theme: _tema,
        routerConfig: _router,
      ),
    );
  }
}
