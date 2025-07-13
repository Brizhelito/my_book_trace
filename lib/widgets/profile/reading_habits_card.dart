import 'package:flutter/material.dart';
import 'package:MyBookTrace/models/reading_session.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Widget que muestra estadísticas sobre hábitos de lectura
class ReadingHabitsCard extends StatelessWidget {
  final List<ReadingSession> sessions;

  const ReadingHabitsCard({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, mostrar mensaje
    if (sessions.isEmpty) {
      return _buildEmptyCard();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hábitos de Lectura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Gráfico de tiempo de lectura por día de la semana
            SizedBox(
              height: 200,
              child: _buildWeekdayChart(),
            ),
            
            const SizedBox(height: 24),
            
            // Estadísticas de ritmo de lectura
            _buildReadingPaceStats(),
          ],
        ),
      ),
    );
  }

  /// Construye un widget vacío cuando no hay datos
  Widget _buildEmptyCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hábitos de Lectura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              heightFactor: 3,
              child: Text(
                'Registra sesiones de lectura para ver tus hábitos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el gráfico de tiempo de lectura por día de la semana
  Widget _buildWeekdayChart() {
    // Calcular tiempo por día de la semana
    final weekdayMinutes = List<double>.filled(7, 0);
    
    for (final session in sessions) {
      // Asumimos que date no es nulo por el diseño del modelo
      final weekday = session.date.weekday - 1; // 0 = lunes, 6 = domingo
      // Convertir la duración (Duration) a minutos como double
      weekdayMinutes[weekday] += (session.duration.inSeconds / 60.0); // Convertir a minutos
    }
    
    // Nombres de los días de la semana
    const weekdayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: weekdayMinutes.reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final minutes = rod.toY.round();
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              return BarTooltipItem(
                '${weekdayNames[groupIndex]}: ${hours > 0 ? '$hours h ' : ''}$mins min',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    weekdayNames[value.toInt()],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
                if (value == 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()} min',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(
          7,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weekdayMinutes[index],
                color: _getBarColor(index),
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obtiene el color para las barras según el día de la semana
  Color _getBarColor(int weekday) {
    // Colores para cada día de la semana
    const colors = [
      Color(0xFF4FC3F7), // Lunes
      Color(0xFF4DB6AC), // Martes
      Color(0xFFAED581), // Miércoles
      Color(0xFFFFD54F), // Jueves
      Color(0xFFFF8A65), // Viernes
      Color(0xFF9575CD), // Sábado
      Color(0xFFF06292), // Domingo
    ];
    
    return colors[weekday];
  }

  /// Construye las estadísticas de ritmo de lectura
  Widget _buildReadingPaceStats() {
    // Calcular estadísticas de ritmo de lectura
    int totalPages = 0;
    Duration totalTime = Duration.zero;
    DateTime? firstSession;
    DateTime? lastSession;
    
    for (final session in sessions) {
      // Calcular páginas leídas
      // Asumimos que startPage y endPage no son nulos por el diseño del modelo
      totalPages += (session.endPage - session.startPage);
      
      // Sumar tiempo de lectura - la duración ya es un objeto Duration
      totalTime += session.duration;
      
      // Determinar primera y última sesión
      // Asumimos que date no es nulo por el diseño del modelo
      if (firstSession == null || session.date.isBefore(firstSession)) {
        firstSession = session.date;
      }
      if (lastSession == null || session.date.isAfter(lastSession)) {
        lastSession = session.date;
      }
    }
    
    // Calcular páginas por hora
    final pagesPerHour = totalTime.inHours > 0 
        ? (totalPages / totalTime.inHours).toStringAsFixed(1)
        : 'N/A';
    
    // Calcular promedio de tiempo por sesión (en minutos)
    final avgSessionTimeMinutes = sessions.isNotEmpty
        ? totalTime.inMinutes / sessions.length
        : 0.0;
    
    // Formatear fechas
    final dateFormat = DateFormat('dd/MM/yyyy');
    final firstSessionStr = firstSession != null 
        ? dateFormat.format(firstSession) 
        : 'N/A';
    final lastSessionStr = lastSession != null 
        ? dateFormat.format(lastSession) 
        : 'N/A';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Ritmo de Lectura',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                _buildStatColumn('Páginas/Hora', pagesPerHour),
                const SizedBox(width: 16),
                _buildStatColumn(
                  'Tiempo Promedio',
                  '${(avgSessionTimeMinutes ~/ 60)}h ${(avgSessionTimeMinutes % 60).toInt()}m',
                ),
                const SizedBox(width: 16),
                _buildStatColumn('Primera Sesión', firstSessionStr),
              ],
            ),
            Row(
              children: [
                const SizedBox(height: 20),
                _buildStatColumn('Última Sesión', lastSessionStr),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Construye una columna con estadística
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
