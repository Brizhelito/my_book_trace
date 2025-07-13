import 'package:flutter/material.dart';

/// Widget que muestra estadísticas de géneros literarios
class GenreStatsCard extends StatelessWidget {
  final Map<String, int> genreCount;
  final Map<String, Duration> genreReadingTime;

  const GenreStatsCard({
    super.key,
    required this.genreCount,
    required this.genreReadingTime,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, mostrar mensaje
    if (genreCount.isEmpty) {
      return _buildEmptyCard(context);
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
              'Géneros Favoritos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Gráfico de géneros por cantidad de libros
                  Expanded(
                    child: _buildGenreCountChart(),
                  ),
                  const SizedBox(width: 16),
                  // Gráfico de géneros por tiempo de lectura
                  Expanded(
                    child: _buildGenreTimeChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un widget vacío cuando no hay datos
  Widget _buildEmptyCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Géneros Favoritos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              heightFactor: 3,
              child: Text(
                'Añade libros con géneros para ver estadísticas',
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

  /// Construye el gráfico de cantidad de libros por género usando barras horizontales
  Widget _buildGenreCountChart() {
    // Ordenar géneros por cantidad de libros
    final sortedGenres = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar los 5 géneros más populares
    final topGenres = sortedGenres.take(5).toList();
    
    // Colores para las barras (compatibles con modo oscuro/claro)
    final colors = [
      Colors.blue.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
    ];

    // Total de libros para calcular porcentajes
    final totalBooks = genreCount.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      children: [
        const Text(
          'Por Cantidad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < topGenres.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del género y cantidad
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    topGenres[i].key,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${topGenres[i].value} libros',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Barra de progreso
                            Stack(
                              children: [
                                // Fondo de la barra
                                Container(
                                  height: 12,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Barra de progreso coloreada
                                FractionallySizedBox(
                                  widthFactor: topGenres[i].value / (totalBooks > 0 ? totalBooks : 1),
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[i % colors.length],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Construye el gráfico de tiempo de lectura por género usando barras horizontales
  Widget _buildGenreTimeChart() {
    // Ordenar géneros por tiempo de lectura
    final sortedGenres = genreReadingTime.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar los 5 géneros con más tiempo de lectura
    final topGenres = sortedGenres.take(5).toList();

    // Colores para las barras (compatibles con modo oscuro/claro)
    final colors = [
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.blue.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
    ];

    // Total de tiempo para calcular porcentajes
    final totalTime = genreReadingTime.values.fold(
      const Duration(seconds: 0),
      (sum, time) => sum + time,
    );
    
    // Función para formatear la duración
    String formatDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      if (hours > 0) {
        return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
      } else {
        return '$minutes min';
      }
    }

    return Column(
      children: [
        const Text(
          'Por Tiempo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < topGenres.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del género y tiempo
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    topGenres[i].key,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formatDuration(topGenres[i].value),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Barra de progreso
                            Stack(
                              children: [
                                // Fondo de la barra
                                Container(
                                  height: 12,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Barra de progreso coloreada
                                FractionallySizedBox(
                                  widthFactor: totalTime.inSeconds > 0
                                      ? topGenres[i].value.inSeconds / totalTime.inSeconds
                                      : 0,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[i % colors.length],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Se eliminó el método _buildGenreLegend() que ya no se utiliza
}
