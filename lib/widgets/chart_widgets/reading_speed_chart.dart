import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_book_trace/providers/reading_session_provider.dart';
import 'package:my_book_trace/models/reading_session.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar un gráfico de velocidad de lectura
class ReadingSpeedChart extends StatelessWidget {
  const ReadingSpeedChart({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<ReadingSessionProvider>(context);
    final sessions = sessionProvider.sessions;
    
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos suficientes para mostrar el gráfico',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    
    // Ordenar sesiones por fecha
    final sortedSessions = List<ReadingSession>.from(sessions)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Si hay demasiados puntos, reducir para mejor visualización
    final List<ReadingSession> displaySessions = sortedSessions.length > 10 
        ? sortedSessions.sublist(sortedSessions.length - 10) 
        : sortedSessions;
    
    // Crear puntos para el gráfico
    final List<FlSpot> spots = [];
    for (var i = 0; i < displaySessions.length; i++) {
      final session = displaySessions[i];
      // Velocidad en páginas por hora
      spots.add(FlSpot(i.toDouble(), session.readingSpeed));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= displaySessions.length) {
                  return const Text('');
                }
                final date = displaySessions[value.toInt()].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 35,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        minX: 0,
        maxX: (displaySessions.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} pág/h',
                  TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
