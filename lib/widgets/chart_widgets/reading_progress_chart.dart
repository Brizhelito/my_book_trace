import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:MyBookTrace/providers/reading_session_provider.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar un gráfico de progreso de lectura
class ReadingProgressChart extends StatelessWidget {
  const ReadingProgressChart({super.key});

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
    
    // Agrupar sesiones por fecha
    final Map<DateTime, int> pagesByDay = {};
    for (var session in sessions) {
      // Normalizar fecha (sin horas, minutos, segundos)
      final date = DateTime(session.date.year, session.date.month, session.date.day);
      pagesByDay[date] = (pagesByDay[date] ?? 0) + session.pagesRead;
    }
    
    // Ordenar las fechas
    final sortedDates = pagesByDay.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Si hay demasiados puntos, reducir para mejor visualización
    final List<DateTime> displayDates = sortedDates.length > 7 
        ? sortedDates.sublist(sortedDates.length - 7) 
        : sortedDates;
    
    // Crear puntos para el gráfico
    final List<FlSpot> spots = [];
    for (var i = 0; i < displayDates.length; i++) {
      final date = displayDates[i];
      spots.add(FlSpot(i.toDouble(), pagesByDay[date]!.toDouble()));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= displayDates.length) {
                  return const Text('');
                }
                final date = displayDates[value.toInt()];
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
                    value.toInt().toString(),
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
          border: Border.all(color: Colors.grey.withAlpha(128)),
        ),
        minX: 0,
        maxX: (displayDates.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withAlpha(51),
            ),
          ),
        ],
      ),
    );
  }
}
