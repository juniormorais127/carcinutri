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
import 'screens/projecao_screen.dart';
import 'screens/viveiro_form_screen.dart';
import 'screens/viveiro_painel_screen.dart';
import 'state/app_state.dart';

final GoRouter _router = GoRouter(
  routes: [
    // Abas principais (rodapé): Início e Projeção.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/projecao', builder: (_, __) => const ProjecaoScreen()),
          ],
        ),
      ],
    ),
    // Telas empilhadas (abrem em tela cheia sobre as abas).
    GoRoute(
        path: '/calculadoras',
        builder: (_, __) => const CalculadorasScreen()),
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
        path: '/crescimento',
        builder: (_, __) => const CrescimentoScreen()),
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
    GoRoute(path: '/biometria', builder: (_, __) => const BiometriaFormScreen()),
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'Projeção'),
        ],
      ),
    );
  }
}

final ThemeData _tema = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16a34a)),
  useMaterial3: true,
  inputDecorationTheme:
      const InputDecorationTheme(border: OutlineInputBorder()),
);

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
