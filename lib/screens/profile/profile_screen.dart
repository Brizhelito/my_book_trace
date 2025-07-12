import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_book_trace/providers/book_provider.dart';
import 'package:my_book_trace/providers/reading_session_provider.dart';
import 'package:my_book_trace/models/book.dart';
import 'package:my_book_trace/models/reading_session.dart';
import 'package:my_book_trace/widgets/profile/genre_stats_card.dart';
import 'package:my_book_trace/widgets/profile/reading_habits_card.dart';
import 'package:my_book_trace/widgets/profile/favorite_books_card.dart';
import 'package:my_book_trace/widgets/profile/challenge_stats_card.dart';

/// Pantalla de perfil del usuario
/// 
/// Muestra estadísticas personalizadas basadas en los hábitos de lectura,
/// géneros favoritos, y desempeño en desafíos.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  List<Book> _books = [];
  List<ReadingSession> _sessions = [];
  
  // Datos procesados para estadísticas
  Map<String, int> _genreCount = {};
  Map<String, Duration> _genreReadingTime = {};
  List<Book> _favoriteBooks = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  /// Carga todos los datos necesarios para el perfil
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar libros
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final books = await bookProvider.getAllBooks();
      
      // Cargar sesiones de lectura
      final sessionProvider = Provider.of<ReadingSessionProvider>(context, listen: false);
      final sessions = await sessionProvider.getAllSessions();
      
      if (mounted) {
        setState(() {
          _books = books;
          _sessions = sessions;
          _processUserData();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos del perfil: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Procesa los datos para generar estadísticas
  void _processUserData() {
    // Reiniciar datos
    _genreCount = {};
    _genreReadingTime = {};
    _favoriteBooks = [];
    
    // Procesar géneros
    for (final book in _books) {
      if (book.genre != null && book.genre!.isNotEmpty) {
        _genreCount[book.genre!] = (_genreCount[book.genre!] ?? 0) + 1;
      }
    }
    
    // Procesar tiempo de lectura por género
    for (final session in _sessions) {
      final book = _books.firstWhere(
        (b) => b.id == session.bookId,
        orElse: () => Book(title: 'Desconocido', author: 'Desconocido'),
      );
      
      // Solo procesamos si el género existe y no está vacío
      if (book.genre != null && book.genre!.isNotEmpty) {
        final genre = book.genre!;
        // Convertir segundos a Duration
        final sessionDuration = Duration(seconds: session.duration);
        
        // Asegurarse de que el valor del mapa sea de tipo Duration
        final currentDuration = _genreReadingTime[genre] ?? Duration.zero;
        _genreReadingTime[genre] = currentDuration + sessionDuration;
      }
    }
    
    // Identificar libros favoritos (más tiempo de lectura)
    final bookReadingTime = <String, Duration>{};
    
    for (final session in _sessions) {
      // Asumimos que bookId no es nulo en el modelo
      final bookId = session.bookId;
      // Convertir segundos a Duration
      final sessionDuration = Duration(seconds: session.duration);
      
      // Asegurarse de que el valor del mapa sea de tipo Duration
      final currentDuration = bookReadingTime[bookId] ?? Duration.zero;
      bookReadingTime[bookId] = currentDuration + sessionDuration;
    }
    
    // Ordenar libros por tiempo de lectura
    final sortedBookIds = bookReadingTime.keys.toList()
      ..sort((a, b) => (bookReadingTime[b] ?? Duration.zero)
          .compareTo(bookReadingTime[a] ?? Duration.zero));
    
    // Tomar los 5 libros con más tiempo de lectura
    _favoriteBooks = sortedBookIds
        .take(5)
        .map((id) => _books.firstWhere(
              (b) => b.id == id,
              orElse: () => Book(title: 'Desconocido', author: 'Desconocido'),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil Lector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado del perfil
                    _buildProfileHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Estadísticas de géneros
                    GenreStatsCard(
                      genreCount: _genreCount,
                      genreReadingTime: _genreReadingTime,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Hábitos de lectura
                    ReadingHabitsCard(sessions: _sessions),
                    
                    const SizedBox(height: 16),
                    
                    // Libros favoritos
                    FavoriteBooksCard(favoriteBooks: _favoriteBooks),
                    
                    const SizedBox(height: 16),
                    
                    // Estadísticas de desafíos
                    const ChallengeStatsCard(),
                  ],
                ),
              ),
            ),
    );
  }
  
  /// Construye el encabezado del perfil con estadísticas generales
  Widget _buildProfileHeader() {
    final totalBooks = _books.length;
    final totalReadingTime = _sessions.fold<Duration>(
      Duration.zero,
      (total, session) {
        // Convertir segundos a Duration
        final sessionDuration = Duration(seconds: session.duration);
        return total + sessionDuration;
      },
    );
    
    final totalPages = _sessions.fold<int>(
      0,
      (total, session) {
        final endPage = session.endPage ?? 0;
        final startPage = session.startPage ?? 0;
        return total + (endPage - startPage);
      },
    );
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Lectura',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.book,
                  '$totalBooks',
                  'Libros',
                  Colors.indigo,
                ),
                _buildStatItem(
                  Icons.timer,
                  _formatDuration(totalReadingTime),
                  'Tiempo Total',
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.menu_book,
                  '$totalPages',
                  'Páginas',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye un elemento de estadística para el encabezado
  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  /// Formatea una duración a un formato legible
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}
