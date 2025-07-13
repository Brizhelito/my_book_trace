import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:my_book_trace/constants/app_constants.dart';
import 'package:my_book_trace/providers/reading_session_provider.dart';
import 'package:my_book_trace/widgets/chart_widgets/reading_progress_chart.dart';
import 'package:my_book_trace/widgets/chart_widgets/reading_speed_chart.dart';

/// Pantalla para mostrar estadísticas de lectura
class ReadingStatisticsScreen extends StatefulWidget {
  static const routeName = '/reading-statistics';

  const ReadingStatisticsScreen({super.key});

  @override
  State<ReadingStatisticsScreen> createState() =>
      _ReadingStatisticsScreenState();
}

class _ReadingStatisticsScreenState extends State<ReadingStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessionProvider = Provider.of<ReadingSessionProvider>(
        context,
        listen: false,
      );
      await sessionProvider.loadSessions();
      await sessionProvider.loadGeneralStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de lectura'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Gráficos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildSummaryTab(), _buildChartsTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'statistics_history_fab',
        onPressed: () {
          context.go(AppRoutes.readingSessionHistory);
        },
        label: const Text('Historial de sesiones'),
        icon: const Icon(Icons.history),
        tooltip: 'Ver historial de sesiones de lectura',
      ),
    );
  }

  Widget _buildSummaryTab() {
    final sessionProvider = Provider.of<ReadingSessionProvider>(context);
    final stats = sessionProvider.generalStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticCard(
            title: 'Resumen general',
            children: [
              _buildStatRow(
                title: 'Sesiones completadas',
                value: '${stats['sessionCount'] ?? 0}',
                icon: Icons.check_circle_outline,
              ),
              _buildStatRow(
                title: 'Días de lectura',
                value: '${stats['readingDays'] ?? 0}',
                icon: Icons.calendar_today,
              ),
              _buildStatRow(
                title: 'Total de páginas leídas',
                value: '${stats['totalPages'] ?? 0}',
                icon: Icons.menu_book,
              ),
              _buildStatRow(
                title: 'Tiempo total de lectura',
                value: sessionProvider.formatDuration(
                  (stats['totalDuration'] is Duration)
                    ? (stats['totalDuration'] as Duration).inSeconds
                    : (stats['totalDuration'] ?? 0),
                ),
                icon: Icons.access_time,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildStatisticCard(
            title: 'Últimas sesiones',
            children: _buildRecentSessionsList(sessionProvider),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentSessionsList(ReadingSessionProvider provider) {
    final sessions = provider.sessions;

    if (sessions.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay sesiones de lectura registradas',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    // Ordenar por fecha más reciente
    final recentSessions = List.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Limitar a las 5 sesiones más recientes
    final displaySessions = recentSessions.take(5).toList();

    return displaySessions.map((session) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('${session.pagesRead} páginas leídas'),
            subtitle: Text(
              'Duración: ${provider.formatDuration(session.duration.inSeconds)}',
            ),
            trailing: Text(
              '${session.date.day}/${session.date.month}/${session.date.year}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          if (session.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notas:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
        ],
      );
    }).toList();
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatisticCard(
            title: 'Progreso de lectura',
            children: [
              const SizedBox(height: 8),
              Container(
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const ReadingProgressChart(),
              ),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 16),

          _buildStatisticCard(
            title: 'Velocidad de lectura',
            children: [
              const SizedBox(height: 8),
              Container(
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const ReadingSpeedChart(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
