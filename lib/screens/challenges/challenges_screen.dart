import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:MyBookTrace/models/challenge.dart';
import 'package:MyBookTrace/providers/challenge_provider.dart';
import 'package:MyBookTrace/widgets/challenges/challenge_card.dart';
import 'package:MyBookTrace/widgets/challenges/create_challenge_dialog.dart';
import 'package:MyBookTrace/widgets/common/loading_indicator.dart';
import 'package:MyBookTrace/widgets/common/empty_state.dart';
import 'package:MyBookTrace/widgets/common/error_message.dart';
import 'package:MyBookTrace/constants/app_constants.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedMonth = DateTime.now();

    // Agregar listener para actualizar la UI cuando cambia la pestaña
    _tabController.addListener(_handleTabSelection);

    // Inicializar datos de localización para español
    initializeDateFormatting('es_ES', null);

    // Cargar los desafíos del mes actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallenges();
    });
  }
  
  // Manejador para el cambio de pestaña
  void _handleTabSelection() {
    // Solo reconstruir si la pestaña cambió y el widget está montado
    if (_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cargar desafíos para el mes seleccionado
  Future<void> _loadChallenges() async {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    await provider.loadMonthlyChallenges(
      _selectedMonth.year,
      _selectedMonth.month,
    );
  }

  // Cambiar al mes anterior
  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
    _loadChallenges();
  }

  // Cambiar al mes siguiente
  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
    _loadChallenges();
  }

  // Mostrar diálogo para crear un nuevo desafío
  void _showCreateChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateChallengeDialog(
        initialStartDate: _selectedMonth,
        initialEndDate: DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
          0,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadChallenges();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desafíos de Lectura'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En Progreso'),
            Tab(text: 'Completados'),
            Tab(text: 'Todos'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de mes
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                  tooltip: 'Mes anterior',
                ),
                Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                  tooltip: 'Mes siguiente',
                ),
              ],
            ),
          ),

          // TabBarView para permitir deslizar entre pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Vista de desafíos en progreso
                _buildChallengeList(0),
                // Vista de desafíos completados
                _buildChallengeList(1),
                // Vista de todos los desafíos
                _buildChallengeList(2),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateChallengeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Desafío'),
        heroTag: 'create_challenge',
      ),
    );
  }

  // Widget para construir la lista de desafíos según la pestaña
  Widget _buildChallengeList(int tabIndex) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const LoadingIndicator();
        }

        if (provider.error != null) {
          return ErrorMessage(
            message: provider.error!,
            onRetry: _loadChallenges,
          );
        }

        // Filtrar desafíos según la pestaña seleccionada
        List<Challenge> challenges;
        switch (tabIndex) {
          case 0: // En Progreso
            challenges = provider.monthlyChallenges
                .where((c) => !c.isCompleted && c.isActive)
                .toList();
            break;
          case 1: // Completados
            challenges = provider.monthlyChallenges
                .where((c) => c.isCompleted)
                .toList();
            break;
          case 2: // Todos
          default:
            challenges = provider.monthlyChallenges;
        }

        if (challenges.isEmpty) {
          // Mostrar mensaje personalizado según la pestaña activa
          String title;
          String message;
          String? buttonLabel;
          VoidCallback? onButtonPressed;

          switch (tabIndex) {
            case 0: // En Progreso
              title = 'No hay desafíos en progreso';
              message = 'Crea un nuevo desafío para comenzar';
              buttonLabel = 'Crear Desafío';
              onButtonPressed = _showCreateChallengeDialog;
              break;
            case 1: // Completados
              title = 'No hay desafíos completados';
              message = 'Completa tus desafíos activos para verlos aquí';
              buttonLabel = null;
              onButtonPressed = null;
              break;
            case 2: // Todos
            default:
              title = 'No hay desafíos';
              message = 'Crea tu primer desafío para este mes';
              buttonLabel = 'Crear Desafío';
              onButtonPressed = _showCreateChallengeDialog;
              break;
          }

          return EmptyState(
            icon: Icons.emoji_events_outlined,
            title: title,
            message: message,
            buttonLabel: buttonLabel,
            onButtonPressed: onButtonPressed,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadChallenges,
          child: ListView.builder(
            padding: const EdgeInsets.all(UiConstants.defaultPadding),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: UiConstants.defaultPadding,
                ),
                child: ChallengeCard(challenge: challenge),
              );
            },
          ),
        );
      },
    );
  }
}
