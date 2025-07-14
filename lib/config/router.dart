import 'package:MyBookTrace/constants/app_constants.dart';
import 'package:MyBookTrace/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importaciones de pantallas
import 'package:MyBookTrace/screens/book_screens/book_list_screen.dart';
import 'package:MyBookTrace/screens/book_screens/book_detail_screen.dart';
import 'package:MyBookTrace/screens/book_screens/add_edit_book_screen.dart';
import 'package:MyBookTrace/screens/reading_screens/active_reading_session_screen.dart';
import 'package:MyBookTrace/screens/reading_screens/reading_statistics_screen.dart';
import 'package:MyBookTrace/screens/reading_screens/reading_session_history_screen.dart';
import 'package:MyBookTrace/screens/challenges/challenges_screen.dart';
import 'package:MyBookTrace/screens/profile/profile_screen.dart';
import 'package:MyBookTrace/widgets/shell_scaffold.dart';
import 'package:MyBookTrace/screens/home_screen.dart';

/// Configuración del enrutador de la aplicación utilizando Go Router
///
/// Define todas las rutas de la aplicación y cómo se relacionan entre sí.
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    // Ruta de splash (fuera de la shell)
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // Configuración de ShellRoute para la navegación principal con barra inferior
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        // Determinamos qué índice está seleccionado basado en la ruta
        int selectedIndex;
        final location = state.matchedLocation;

        if (location.startsWith(AppRoutes.home)) {
          selectedIndex = 0;
        } else if (location.startsWith('/books')) {
          selectedIndex = 1;
        } else if (location.startsWith(AppRoutes.statistics)) {
          selectedIndex = 2;
        } else if (location.startsWith(AppRoutes.challenges)) {
          selectedIndex = 3;
        } else if (location.startsWith(AppRoutes.profile)) {
          selectedIndex = 4;
        } else {
          selectedIndex = 0; // Default a home
        }

        return ShellScaffold(
          selectedIndex: selectedIndex,
          shellNavigatorKey: shellNavigatorKey,
          child: child,
        );
      },
      routes: [
        // Rutas dentro de la shell - Todas comparten la barra de navegación
        // Ruta de home
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),

        // Rutas de libros - Books branch
        GoRoute(
          path: AppRoutes.bookList, // '/books'
          builder: (context, state) => const BookListScreen(),
          routes: [
            // Anidamos las rutas que deben mantener el shell
            GoRoute(
              path: 'add', // Se convierte en '/books/add'
              pageBuilder: (context, state) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: const AddEditBookScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                );
              },
            ),
            GoRoute(
              path: ':id', // Se convierte en '/books/:id'
              pageBuilder: (context, state) {
                final bookId = state.pathParameters['id']!;
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: BookDetailScreen(bookId: bookId),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                );
              },
            ),
            GoRoute(
              path: ':id/edit', // Se convierte en '/books/:id/edit'
              pageBuilder: (context, state) {
                final bookId = state.pathParameters['id']!;
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: AddEditBookScreen(bookId: bookId),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                );
              },
            ),
          ],
        ),

        // Rutas de estadísticas - Statistics branch
        GoRoute(
          path: AppRoutes.statistics,
          builder: (context, state) => const ReadingStatisticsScreen(),
        ),
        // Ruta para el historial de sesiones de lectura
        GoRoute(
          path: AppRoutes.readingSessionHistory,
          builder: (context, state) {
            return const ReadingSessionHistoryScreen();
          },
        ),
        // Ruta de desafíos - Challenges branch
        GoRoute(
          path: AppRoutes.challenges,
          builder: (context, state) => const ChallengesScreen(),
        ),
        
        // Ruta de perfil - Profile branch
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.activeReadingSession,
      builder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return ActiveReadingSessionScreen(bookId: bookId);
      },
    ),

    // Rutas para estadísticas y desafíos
    GoRoute(
      path: AppRoutes.statistics,
      builder: (context, state) => const ReadingStatisticsScreen(),
    ),
  ],

  // Configuración de errores
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Página no encontrada')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Error 404',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('La página que buscas no existe.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    ),
  ),
);
