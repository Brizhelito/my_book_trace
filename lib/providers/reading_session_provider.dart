import 'package:flutter/material.dart';
import 'package:my_book_trace/models/reading_session.dart';
import 'package:my_book_trace/repositories/reading_session_repository.dart';

/// Provider para manejar el estado de las sesiones de lectura
class ReadingSessionProvider extends ChangeNotifier {
  final ReadingSessionRepository _repository = ReadingSessionRepository();

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
