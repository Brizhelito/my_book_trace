import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_book_trace/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:my_book_trace/providers/book_provider.dart';
import 'package:my_book_trace/providers/challenge_provider.dart';
import 'package:my_book_trace/widgets/challenges/challenge_card.dart';

/// Widget que muestra el contenido principal de la pantalla de inicio
/// Separado para poder integrarlo directamente en el router
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // Inicializar el provider de libros
    Future.microtask(() {
      context.read<BookProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de resumen
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de lectura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatisticItem(
                        'Leyendo',
                        bookProvider.readingCount.toString(),
                        Icons.auto_stories,
                        Colors.blue,
                      ),
                      _buildStatisticItem(
                        'Completados',
                        bookProvider.completedCount.toString(),
                        Icons.task_alt,
                        Colors.green,
                      ),
                      _buildStatisticItem(
                        'Pendientes',
                        bookProvider.notStartedCount.toString(),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Continuar leyendo
          Text(
            'Continuar leyendo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Lista de libros en progreso
          SizedBox(
            height: 200,
            child: bookProvider.readingCount > 0
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: bookProvider.books
                        .where((book) => book.status == 'en_progreso')
                        .length,
                    itemBuilder: (context, index) {
                      final book = bookProvider.books
                          .where((book) => book.status == 'en_progreso')
                          .toList()[index];

                      return _buildBookCard(book);
                    },
                  )
                : const Center(child: Text('No tienes libros en progreso')),
          ),

          const SizedBox(height: 24),

          // Desafíos activos
          Text(
            'Desafíos activos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Desafíos activos reales
          Consumer<ChallengeProvider>(
            builder: (context, challengeProvider, _) {
              final activeChallenges = challengeProvider.activeChallenges;
              if (challengeProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (activeChallenges.isEmpty) {
                return const Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.emoji_events, color: Colors.white),
                    ),
                    title: Text('Sin desafíos activos'),
                    subtitle: Text('Crea un desafío para motivarte a leer más'),
                  ),
                );
              }
              return Column(
                children: activeChallenges.map((challenge) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ChallengeCard(challenge: challenge),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget para mostrar un elemento estadístico
  Widget _buildStatisticItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // Widget para mostrar una tarjeta de libro
  Widget _buildBookCard(dynamic book) {
    return GestureDetector(
      onTap: () {
        if (book.id != null) {
          context.push(AppRoutes.bookDetailPath(book.id));
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada del libro
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: book.coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(book.coverImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: book.coverImageUrl == null
                    ? const Icon(Icons.book, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Título del libro
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Autor del libro
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
