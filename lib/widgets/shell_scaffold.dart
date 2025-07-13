import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:MyBookTrace/constants/app_constants.dart';

/// Widget de Scaffold para manejar la shell de navegación con barra inferior
/// Este widget mantiene la barra de navegación visible mientras cambia el contenido principal
class ShellScaffold extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final GlobalKey<NavigatorState> shellNavigatorKey;

  const ShellScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.shellNavigatorKey,
  });

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  // Lista de íconos para la barra de navegación
  final List<IconData> _navigationIcons = [
    Icons.home_rounded,
    Icons.library_books_rounded,
    Icons.bar_chart_rounded,
    Icons.emoji_events_rounded,
    Icons.person_rounded,
  ];

  // Títulos para cada sección
  final List<String> _sectionTitles = [
    'Inicio',
    'Biblioteca',
    'Estadísticas',
    'Desafíos',
    'Perfil',
  ];

  @override
  void initState() {
    super.initState();
    // Registrar el interceptor de botón atrás
    BackButtonInterceptor.add(_backButtonInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_backButtonInterceptor);
    super.dispose();
  }

  // Función que intercepta el botón atrás
  bool _backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    // Obtener la ubicación actual de la ruta completa
    final String location = GoRouterState.of(context).uri.toString();
    debugPrint('BackButtonInterceptor: location = $location');

    // Exactamente la ruta /home: mostrar diálogo
    if (location == '/home') {
      debugPrint('BackButtonInterceptor: En HOME, mostrando diálogo');
      _onWillPop(context).then((shouldPop) {
        if (shouldPop) {
          SystemNavigator.pop();
        }
      });
      return true; // Interceptamos para mostrar diálogo
    }
    // Exactamente rutas principales del primer nivel
    else if (location == '/books' ||
        location == '/statistics' ||
        location == '/challenges' ||
        location == '/profile' ||
        location == '/reading_session_history') {
      debugPrint('BackButtonInterceptor: En ruta principal, yendo a HOME');
      context.go('/home');
      return true; // Interceptamos para ir a home
    }

    // En subrutas como /books/123: NO interceptar (dejar que Flutter/GoRouter maneje)
    debugPrint(
      'BackButtonInterceptor: En subruta, permitiendo navegación normal',
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: (int index) {
          _navigateToTab(context, index);
        },
        destinations: List.generate(_navigationIcons.length, (index) {
          return NavigationDestination(
            icon: Icon(_navigationIcons[index]),
            label: _sectionTitles[index],
          );
        }),
      ),
    );
  }

  // Navegar a la sección correspondiente
  void _navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.bookList);
        break;
      case 2:
        context.go(AppRoutes.statistics);
        break;
      case 3:
        context.go(AppRoutes.challenges);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  /// Muestra un diálogo de confirmación cuando el usuario intenta salir de la app
  /// Retorna true si el usuario confirma que desea salir
  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Deseas salir de la aplicación?'),
            content: const Text(
              'Presiona Cancelar para permanecer en la aplicación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }
}
