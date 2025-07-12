import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_book_trace/constants/app_constants.dart';

// Importaciones de pantallas
import 'package:my_book_trace/screens/splash_screen.dart';
import 'package:my_book_trace/screens/book_screens/book_list_screen.dart';
import 'package:my_book_trace/screens/book_screens/book_detail_screen.dart';
import 'package:my_book_trace/screens/book_screens/add_edit_book_screen.dart';
import 'package:my_book_trace/screens/reading_screens/active_reading_session_screen.dart';
import 'package:my_book_trace/screens/reading_screens/reading_statistics_screen.dart';
import 'package:my_book_trace/screens/reading_screens/reading_session_history_screen.dart';
import 'package:my_book_trace/screens/challenges/challenges_screen.dart';
import 'package:my_book_trace/screens/profile/profile_screen.dart';
import 'package:my_book_trace/widgets/shell_scaffold.dart';
import 'package:my_book_trace/screens/home_screen.dart';

/// Configuración del enrutador de la aplicación utilizando Go Router
///
/// Define todas las rutas de la aplicación y cómo se relacionan entre sí.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    // Ruta de splash (fuera de la shell)
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // Configuración de ShellRoute para la navegación principal con barra inferior
    ShellRoute(
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

        return ShellScaffold(selectedIndex: selectedIndex, child: child);
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
          path: AppRoutes.bookList,
          builder: (context, state) => const BookListScreen(),
        ),

        // Rutas de estadísticas - Statistics branch
        GoRoute(
          path: AppRoutes.statistics,
          builder: (context, state) => const ReadingStatisticsScreen(),
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

    // Ruta para añadir libro
    GoRoute(
      path: AppRoutes.addBook,
      pageBuilder: (context, state) {
        debugPrint('Router: Navegando a AddEditBookScreen (añadir nuevo libro)');
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: const AddEditBookScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),

    GoRoute(
      path: AppRoutes.editBook,
      pageBuilder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: AddEditBookScreen(bookId: bookId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),

    // Rutas fuera de la shell - No tienen la barra de navegación
    // Rutas de detalle de libro
    GoRoute(
      path: AppRoutes.bookDetail,
      pageBuilder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: BookDetailScreen(bookId: bookId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
      routes: [
        // Ruta anidada para notas del libro
        GoRoute(
          path: AppRoutes.bookNotes,
          pageBuilder: (context, state) {
            final bookId = state.pathParameters['id']!;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: BookDetailScreen(bookId: bookId, initialTab: 'notes'),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        // Ruta anidada para estadísticas del libro
        GoRoute(
          path: AppRoutes.bookStats,
          pageBuilder: (context, state) {
            final bookId = state.pathParameters['id']!;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: BookDetailScreen(bookId: bookId, initialTab: 'stats'),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
      ],
    ),

    // Rutas relacionadas con sesiones de lectura
    /* // Ruta comentada hasta implementar la pantalla correspondiente
    GoRoute(
      path: AppRoutes.readingSession,
      builder: (context, state) {
        final sessionId = state.pathParameters['id']!;
        return ReadingSessionScreen(sessionId: sessionId);
      },
    ),
    */
    GoRoute(
      path: AppRoutes.activeReadingSession,
      builder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return ActiveReadingSessionScreen(bookId: bookId);
      },
    ),

    // Ruta para el historial de sesiones de lectura
    GoRoute(
      path: AppRoutes.readingSessionHistory,
      builder: (context, state) {
        return const ReadingSessionHistoryScreen();
      },
    ),

    // Rutas para estadísticas y desafíos
    GoRoute(
      path: AppRoutes.statistics,
      builder: (context, state) => const ReadingStatisticsScreen(),
    ),

    /* // Rutas comentadas hasta implementar las pantallas correspondientes
    GoRoute(
      path: AppRoutes.challenges,
      builder: (context, state) => const ChallengesScreen(),
    ),
    
    // Rutas de perfil y configuración
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    */
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

  // Redirecciones
  redirect: (BuildContext context, GoRouterState state) {
    // Aquí podríamos implementar redirecciones condicionales,
    // por ejemplo, para verificar autenticación o estado de onboarding
    return null; // Sin redirecciones por ahora
  },
);
