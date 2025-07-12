import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_book_trace/constants/app_constants.dart';

/// Widget de Scaffold para manejar la shell de navegación con barra inferior
/// Este widget mantiene la barra de navegación visible mientras cambia el contenido principal
class ShellScaffold extends StatefulWidget {
  /// Widget hijo a mostrar como contenido principal
  final Widget child;

  /// Índice de la pestaña seleccionada
  final int selectedIndex;

  const ShellScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
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
}
