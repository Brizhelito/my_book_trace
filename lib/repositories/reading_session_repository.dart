import 'package:my_book_trace/models/reading_session.dart';
import 'package:my_book_trace/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Repositorio para gestionar sesiones de lectura en la base de datos
class ReadingSessionRepository {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  
  /// Obtener instancia de la base de datos
  Future<Database> getDatabase() async {
    return await _databaseService.database;
  }

  /// Crear tabla de sesiones de lectura
  Future<void> createTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_sessions(
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        start_page INTEGER NOT NULL,
        end_page INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Añadir una nueva sesión de lectura
  Future<ReadingSession> addReadingSession(ReadingSession session) async {
    try {
      final db = await _databaseService.database;
      
      // Generar ID si no existe
      final sessionWithId = session.id == null
          ? session.copyWith(id: _uuid.v4())
          : session;
      
      // Validar los datos antes de insertar
      final sessionMap = sessionWithId.toMap();
      print('DEBUG - Insertando sesión: ${sessionMap.toString()}');
      
      // Asegurarse que ningún campo requerido sea nulo
      if (sessionMap['book_id'] == null || sessionMap['book_id'].toString().isEmpty) {
        throw Exception('book_id es nulo o vacío: ${sessionMap['book_id']}');
      }
      
      // Intentar insertar en la base de datos
      await db.insert(
        'reading_sessions',
        sessionMap,
      );
      
      print('DEBUG - Sesión insertada correctamente con id: ${sessionWithId.id}');
      return sessionWithId;
    } catch (e, stackTrace) {
      print('ERROR - No se pudo guardar la sesión de lectura: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-lanzar el error para manejarlo en el provider
    }
  }

  /// Obtener todas las sesiones de lectura
  Future<List<ReadingSession>> getAllReadingSessions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('reading_sessions');
    
    return List.generate(maps.length, (i) {
      return ReadingSession.fromMap(maps[i]);
    });
  }

  /// Obtener sesiones de lectura por ID de libro
  Future<List<ReadingSession>> getReadingSessionsByBook(String bookId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_sessions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'start_time DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ReadingSession.fromMap(maps[i]);
    });
  }

  /// Obtener una sesión de lectura por su ID
  Future<ReadingSession?> getReadingSessionById(String id) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    // Asegurar que las notas no sean nulas
    final map = maps.first;
    if (map['notes'] == null) {
      map['notes'] = '';
    }
    
    return ReadingSession.fromMap(map);
  }

  /// Actualizar una sesión de lectura
  Future<void> updateReadingSession(ReadingSession session) async {
    final db = await _databaseService.database;
    
    await db.update(
      'reading_sessions',
      session.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Eliminar una sesión de lectura
  Future<void> deleteReadingSession(String id) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Obtener estadísticas de lectura para un libro específico
  Future<Map<String, dynamic>> getBookReadingStats(String bookId) async {
    final db = await _databaseService.database;
    
    // Total de sesiones para el libro
    final sessionCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reading_sessions WHERE book_id = ?',
      [bookId],
    )) ?? 0;
    
    // Tiempo total de lectura (en segundos)
    final totalDurationMinutes = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT SUM(duration_minutes) FROM reading_sessions WHERE book_id = ?',
      [bookId],
    )) ?? 0;
    final totalDuration = totalDurationMinutes * 60; // Convertir minutos a segundos
    
    // Total de páginas leídas
    final totalPages = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT SUM(end_page - start_page) FROM reading_sessions WHERE book_id = ?',
      [bookId],
    )) ?? 0;
    
    // Velocidad promedio (páginas por hora)
    double avgSpeed = 0;
    if (totalDuration > 0) {
      avgSpeed = (totalPages * 3600) / totalDuration;
    }
    
    return {
      'sessionCount': sessionCount,
      'totalDuration': totalDuration,
      'totalPages': totalPages,
      'averageSpeed': avgSpeed,
    };
  }
  
  /// Obtener estadísticas generales de lectura
  Future<Map<String, dynamic>> getGeneralReadingStats() async {
    final db = await _databaseService.database;
    
    // Total de sesiones
    final sessionCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reading_sessions',
    )) ?? 0;
    
    // Tiempo total de lectura (en segundos)
    final totalDurationMinutes = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT SUM(duration_minutes) FROM reading_sessions',
    )) ?? 0;
    final totalDuration = totalDurationMinutes * 60; // Convertir minutos a segundos
    
    // Total de páginas leídas
    final totalPages = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT SUM(end_page - start_page) FROM reading_sessions',
    )) ?? 0;
    
    // Número de días con al menos una sesión de lectura
    final readingDays = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(DISTINCT date(start_time/1000, 'unixepoch')) 
      FROM reading_sessions
    ''')) ?? 0;
    
    return {
      'sessionCount': sessionCount,
      'totalDuration': totalDuration,
      'totalPages': totalPages,
      'readingDays': readingDays,
    };
  }
}
