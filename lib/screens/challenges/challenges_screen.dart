import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_book_trace/models/challenge.dart';
import 'package:my_book_trace/providers/challenge_provider.dart';
import 'package:my_book_trace/widgets/challenges/challenge_card.dart';
import 'package:my_book_trace/widgets/challenges/create_challenge_dialog.dart';
import 'package:my_book_trace/widgets/common/loading_indicator.dart';
import 'package:my_book_trace/widgets/common/empty_state.dart';
import 'package:my_book_trace/widgets/common/error_message.dart';
import 'package:my_book_trace/constants/app_constants.dart';

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

    // Inicializar datos de localización para español
    initializeDateFormatting('es_ES', null);

    // Cargar los desafíos del mes actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallenges();
    });
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

          // Lista de desafíos
          Expanded(
            child: Consumer<ChallengeProvider>(
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
                switch (_tabController.index) {
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
                  return EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No hay desafíos',
                    message: 'Crea tu primer desafío para este mes',
                    buttonLabel: 'Crear Desafío',
                    onButtonPressed: _showCreateChallengeDialog,
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
}
