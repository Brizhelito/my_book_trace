import 'package:flutter/material.dart';
import 'package:my_book_trace/models/reading_session.dart';
import 'package:my_book_trace/repositories/reading_session_repository.dart';
import 'package:my_book_trace/providers/challenge_provider.dart';
import 'package:my_book_trace/models/challenge.dart';
import 'package:my_book_trace/providers/book_provider.dart';
import 'package:my_book_trace/models/book.dart';

/// Provider para manejar el estado de las sesiones de lectura
class ReadingSessionProvider extends ChangeNotifier {
  final ReadingSessionRepository _repository = ReadingSessionRepository();
  
  // Referencia a otros providers
  ChallengeProvider? _challengeProvider;
  BookProvider? _bookProvider;
  
  // Control de inicialización
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<ReadingSession> _sessions = [];
  ReadingSession? _selectedSession;
  Map<String, List<ReadingSession>> _sessionsByBook = {};

  // Getters
  List<ReadingSession> get sessions => _sessions;
  ReadingSession? get selectedSession => _selectedSession;
  Map<String, List<ReadingSession>> get sessionsByBook => _sessionsByBook;

  // Estadísticas de lectura
  Map<String, dynamic> _generalStats = {};
  final Map<String, Map<String, dynamic>> _bookStats = {};

  Map<String, dynamic> get generalStats => _generalStats;
  Map<String, dynamic> getBookStats(String bookId) => _bookStats[bookId] ?? {};

  // Inicializar provider
  Future<void> initialize() async {
    await _repository.createTable();
    await loadSessions();
    await loadGeneralStats();
    _isInitialized = true;
    debugPrint('ReadingSessionProvider inicializado completamente');
  }
  
  // Establecer referencia al ChallengeProvider
  void setChallengeProvider(ChallengeProvider provider) {
    _challengeProvider = provider;
    debugPrint('ChallengeProvider establecido en ReadingSessionProvider');
  }
  
  // Establecer referencia al BookProvider
  void setBookProvider(BookProvider provider) {
    _bookProvider = provider;
    debugPrint('BookProvider establecido en ReadingSessionProvider');
  }

  // Cargar todas las sesiones
  Future<void> loadSessions() async {
    try {
      _sessions = await _repository.getAllReadingSessions();

      // Agrupar sesiones por libro
      _sessionsByBook = {};
      for (var session in _sessions) {
        if (!_sessionsByBook.containsKey(session.bookId)) {
          _sessionsByBook[session.bookId] = [];
        }
        _sessionsByBook[session.bookId]!.add(session);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar sesiones: $e');
    }
  }
  
  /// Obtiene todas las sesiones de lectura
  Future<List<ReadingSession>> getAllSessions() async {
    try {
      return await _repository.getAllReadingSessions();
    } catch (e) {
      debugPrint('Error al obtener todas las sesiones: $e');
      return [];
    }
  }

  // Cargar sesiones para un libro específico
  Future<List<ReadingSession>> loadSessionsForBook(String bookId) async {
    try {
      final sessions = await _repository.getReadingSessionsByBook(bookId);
      _sessionsByBook[bookId] = sessions;

      // Actualizar estadísticas para este libro
      await loadBookStats(bookId);

      notifyListeners();
      return sessions;
    } catch (e) {
      debugPrint('Error al cargar sesiones del libro: $e');
      return [];
    }
  }

  // Cargar estadísticas generales
  Future<void> loadGeneralStats() async {
    try {
      _generalStats = await _repository.getGeneralReadingStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar estadísticas generales: $e');
    }
  }

  // Cargar estadísticas de un libro
  Future<void> loadBookStats(String bookId) async {
    try {
      final stats = await _repository.getBookReadingStats(bookId);
      _bookStats[bookId] = stats;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar estadísticas del libro: $e');
    }
  }
  
  /// Actualiza automáticamente los desafíos relevantes tras añadir o editar una sesión
  Future<void> _updateChallengesAfterSession(ReadingSession session) async {
    // Validación inicial de dependencias
    if (_challengeProvider == null) {
      debugPrint('Error: ChallengeProvider no inicializado. No se actualizarán los desafíos.');
      return;
    }
    
    // Validación de la sesión
    if (session.id == null || session.id!.isEmpty) {
      debugPrint('Error: Sesión inválida. No se actualizarán los desafíos.');
      return;
    }
    
    try {
      // Obtener todos los desafíos activos
      final activeChallenges = _challengeProvider!.activeChallenges;
      if (activeChallenges.isEmpty) {
        debugPrint('No hay desafíos activos para actualizar.');
        return;
      }
      
      debugPrint('Actualizando desafíos para sesión ID: ${session.id}, Libro ID: ${session.bookId}');
      
      // 1. Actualizar desafíos de páginas leídas
      final pagesChallenges = activeChallenges
          .where((c) => c.type == ChallengeType.pages && 
                !c.isCompleted && 
                c.id != null && 
                c.id!.isNotEmpty)
          .toList();
          
      if (pagesChallenges.isNotEmpty) {
        // Validación de páginas válidas
        final pagesRead = session.endPage - session.startPage;
        if (pagesRead <= 0) {
          debugPrint('Advertencia: Páginas leídas inválidas (${pagesRead}). No se actualizarán desafíos de páginas.');
        } else {
          debugPrint('Actualizando ${pagesChallenges.length} desafíos de páginas con $pagesRead páginas leídas');
          for (final challenge in pagesChallenges) {
            try {
              // Actualizar progreso sumando las páginas leídas en esta sesión
              final newProgress = challenge.currentProgress + pagesRead;
              await _challengeProvider!.updateProgress(challenge.id!, newProgress);
              debugPrint('Desafío de páginas actualizado: ${challenge.title}, Progreso: $newProgress/${challenge.target}');
            } catch (e) {
              debugPrint('Error al actualizar desafío de páginas ${challenge.id}: $e');
            }
          }
        }
      }
      
      // 2. Actualizar desafíos de tiempo de lectura
      final timeChallenges = activeChallenges
          .where((c) => c.type == ChallengeType.time && 
                !c.isCompleted && 
                c.id != null && 
                c.id!.isNotEmpty)
          .toList();
          
      if (timeChallenges.isNotEmpty) {
        // Validar que la duración sea válida
        if (session.duration.inSeconds <= 0) {
          debugPrint('Advertencia: Duración inválida (${session.duration}). No se actualizarán desafíos de tiempo.');
        } else {
          // La duración está en segundos, convertir a minutos
          final minutesRead = session.duration.inMinutes;
          debugPrint('Actualizando ${timeChallenges.length} desafíos de tiempo con $minutesRead minutos leídos');
          
          for (final challenge in timeChallenges) {
            try {
              // Actualizar progreso sumando los minutos leídos en esta sesión
              final newProgress = challenge.currentProgress + minutesRead;
              await _challengeProvider!.updateProgress(challenge.id!, newProgress);
              debugPrint('Desafío de tiempo actualizado: ${challenge.title}, Progreso: $newProgress/${challenge.target}');
            } catch (e) {
              debugPrint('Error al actualizar desafío de tiempo ${challenge.id}: $e');
            }
          }
        }
      }
      
      // 3. Actualizar desafíos de libros completados (si el libro se marcó como completado)
      if (_bookProvider != null) {
        try {
          // Validar que el ID del libro sea válido
          if (session.bookId.isEmpty) {
            debugPrint('Error: ID de libro inválido. No se actualizarán desafíos de libros.');
          } else {
            // Usamos selectBook que actualiza el selectedBook en el provider
            await _bookProvider!.selectBook(session.bookId);
            final book = _bookProvider!.selectedBook;
            
            // Validar que el libro existe
            if (book == null) {
              debugPrint('Advertencia: No se encontró el libro con ID ${session.bookId}. No se actualizarán desafíos de libros.');
            } else {
              final bookChallenges = activeChallenges
                  .where((c) => c.type == ChallengeType.books && 
                        !c.isCompleted && 
                        c.id != null && 
                        c.id!.isNotEmpty)
                  .toList();
                  
              if (bookChallenges.isNotEmpty) {
                // Verificar si el libro se completó con esta sesión
                // Un libro se considera completado si su estado es COMPLETED
                final wasJustCompleted = book.status == Book.STATUS_COMPLETED &&
                                     book.pageCount != null && 
                                     session.endPage >= book.pageCount!;
                
                if (wasJustCompleted) {
                  debugPrint('Libro "${book.title}" completado. Actualizando ${bookChallenges.length} desafíos de libros');
                  
                  for (final challenge in bookChallenges) {
                    try {
                      // Incrementar el contador de libros completados
                      final newProgress = challenge.currentProgress + 1;
                      await _challengeProvider!.updateProgress(challenge.id!, newProgress);
                      debugPrint('Desafío de libros actualizado: ${challenge.title}, Progreso: $newProgress/${challenge.target}');
                    } catch (e) {
                      debugPrint('Error al actualizar desafío de libros ${challenge.id}: $e');
                    }
                  }
                } else {
                  debugPrint('Libro "${book.title}" no completado aún (${session.endPage}/${book.pageCount ?? "?"}). No se actualizarán desafíos de libros.');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error al procesar desafíos de libros: $e');
        }
      } else {
        debugPrint('BookProvider no inicializado. No se actualizarán desafíos de libros.');
      }
      
      // 4. Actualizar desafíos de racha de lectura
      final streakChallenges = activeChallenges
          .where((c) => c.type == ChallengeType.streak && 
                !c.isCompleted && 
                c.id != null && 
                c.id!.isNotEmpty)
          .toList();
      
      if (streakChallenges.isNotEmpty) {
        try {
          debugPrint('Procesando ${streakChallenges.length} desafíos de racha');
          
          // Obtener la fecha actual para comparar
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final yesterday = todayDate.subtract(const Duration(days: 1));
          
          // Validar que tengamos sesiones válidas para comparar fechas
          if (_sessions.isEmpty) {
            debugPrint('No hay sesiones previas para determinar racha. Inicializando con sesión actual.');
          }
          
          // Verificar si ya hemos leído hoy (si ya hay una sesión con la fecha actual)
          final sessionsToday = _sessions.where((s) {
            try {
              final sessionDate = DateTime(s.date.year, s.date.month, s.date.day);
              return sessionDate.isAtSameMomentAs(todayDate);
            } catch (e) {
              debugPrint('Error al comparar fecha de sesión ${s.id}: $e');
              return false;
            }
          }).toList();
          
          // Verificar si leímos ayer
          final sessionsYesterday = _sessions.where((s) {
            try {
              final sessionDate = DateTime(s.date.year, s.date.month, s.date.day);
              return sessionDate.isAtSameMomentAs(yesterday);
            } catch (e) {
              debugPrint('Error al comparar fecha de sesión ${s.id}: $e');
              return false;
            }
          }).toList();
          
          debugPrint('Sesiones hoy: ${sessionsToday.length}, Sesiones ayer: ${sessionsYesterday.length}');
          
          // Para cada desafío de racha, verificamos y actualizamos
          for (final challenge in streakChallenges) {
            try {
              // Si ya hemos leído hoy (incluyendo esta sesión)
              if (sessionsToday.isNotEmpty) {
                // Verificar si la sesión actual es la primera del día
                final isFirstSessionToday = sessionsToday.length == 1 && 
                                           sessionsToday.first.id == session.id;
                
                // Verificar si debemos actualizar la racha
                if (isFirstSessionToday || sessionsYesterday.isNotEmpty) {
                  // Incrementar la racha en 1 día
                  final newProgress = challenge.currentProgress + 1;
                  await _challengeProvider!.updateProgress(challenge.id!, newProgress);
                  debugPrint('Desafío de racha actualizado: ${challenge.title}, Progreso: $newProgress/${challenge.target}');
                } else {
                  // Ya había sesiones hoy, no incrementamos nuevamente
                  debugPrint('Ya existían sesiones para hoy. No se actualiza la racha.');
                }
              } else if (sessionsYesterday.isEmpty) {
                // Si no leímos ayer, reiniciar la racha a 1 (día actual)
                await _challengeProvider!.updateProgress(challenge.id!, 1);
                debugPrint('Desafío de racha reiniciado: ${challenge.title}, Progreso: 1/${challenge.target}');
              }
            } catch (e) {
              debugPrint('Error al actualizar desafío de racha ${challenge.id}: $e');
            }
          }
        } catch (e) {
          debugPrint('Error al procesar desafíos de racha: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Error al actualizar desafíos tras sesión: $e');
    }
  }

  // Seleccionar una sesión
  Future<void> selectSession(String sessionId) async {
    try {
      _selectedSession = await _repository.getReadingSessionById(sessionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al seleccionar sesión: $e');
    }
  }

  // Añadir sesión
  Future<ReadingSession?> addSession(ReadingSession session) async {
    try {
      // Validar book_id - punto crítico
      if (session.bookId.isEmpty) {
        debugPrint('Error: Intento de guardar sesión con bookId vacío');
        return null;
      }
      
      debugPrint('Validando sesión antes de guardar:');
      debugPrint('book_id: ${session.bookId}');
      debugPrint('start_page: ${session.startPage}');
      debugPrint('end_page: ${session.endPage}');
      debugPrint('duration: ${session.duration}');
      debugPrint('notes: "${session.notes}" (longitud: ${session.notes.length})');

      // Verificar que el libro existe antes de asociar la sesión
      final db = await _repository.getDatabase();
      final bookExists = await db.query(
        'books',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [session.bookId],
        limit: 1,
      );

      if (bookExists.isEmpty) {
        debugPrint('Error: No se encontró el libro con ID: ${session.bookId}');
        return null;
      }

      // Clonar la sesión para garantizar que no hay nulos
      final validatedSession = session.copyWith(
        notes: session.notes.trim(),  // Asegurar que las notas están recortadas
      );

      debugPrint('Guardando sesión validada para libro ${validatedSession.bookId} en el repositorio');
      
      // Intentar guardar la sesión en el repositorio
      final newSession = await _repository.addReadingSession(validatedSession);
      
      if (newSession.id == null) {
        throw Exception('La sesión guardada no tiene ID válido');
      }
      
      debugPrint('Sesión guardada exitosamente con ID: ${newSession.id}');

      // Actualizar listas en memoria
      _sessions.add(newSession);
      
      if (!_sessionsByBook.containsKey(newSession.bookId)) {
        _sessionsByBook[newSession.bookId] = [];
      }
      _sessionsByBook[newSession.bookId]!.add(newSession);

      // Actualizar estadísticas
      await loadBookStats(newSession.bookId);
      await loadGeneralStats();
      
      // Actualizar desafíos automáticamente
      await _updateChallengesAfterSession(newSession);

      notifyListeners();
      return newSession;
    } catch (e, stackTrace) {
      debugPrint('Error al añadir sesión: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Actualizar sesión
  Future<bool> updateSession(ReadingSession session) async {
    try {
      await _repository.updateReadingSession(session);

      // Actualizar listas
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
      }

      if (_sessionsByBook.containsKey(session.bookId)) {
        final bookIndex = _sessionsByBook[session.bookId]!.indexWhere(
          (s) => s.id == session.id,
        );
        if (bookIndex != -1) {
          _sessionsByBook[session.bookId]![bookIndex] = session;
        }
      }

      // Actualizar sesión seleccionada si corresponde
      if (_selectedSession != null && _selectedSession!.id == session.id) {
        _selectedSession = session;
      }

      // Actualizar estadísticas
      await loadBookStats(session.bookId);
      await loadGeneralStats();

      // Actualizar desafíos automáticamente
      await _updateChallengesAfterSession(session);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar sesión: $e');
      return false;
    }
  }

  // Eliminar sesión
  Future<bool> deleteSession(String id) async {
    try {
      final sessionToDelete = _sessions.firstWhere((s) => s.id == id);
      final bookId = sessionToDelete.bookId;

      await _repository.deleteReadingSession(id);

      // Actualizar listas
      _sessions.removeWhere((s) => s.id == id);

      if (_sessionsByBook.containsKey(bookId)) {
        _sessionsByBook[bookId]!.removeWhere((s) => s.id == id);
      }

      // Si era la sesión seleccionada, limpiarla
      if (_selectedSession != null && _selectedSession!.id == id) {
        _selectedSession = null;
      }

      // Actualizar estadísticas
      await loadBookStats(bookId);
      await loadGeneralStats();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar sesión: $e');
      return false;
    }
  }

  // Formatear duración (segundos) a formato legible
  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} m';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
}
