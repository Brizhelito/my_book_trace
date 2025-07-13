import 'dart:async';
import 'package:MyBookTrace/models/reading_session.dart';
import 'package:MyBookTrace/services/database_service.dart';
import 'package:MyBookTrace/services/logger_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Repositorio para gestionar sesiones de lectura en la base de datos
class ReadingSessionRepository {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  
  /// Obtener instancia de la base de datos
  Future<Database> getDatabase() async {
    return _databaseService.database;
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
      final db = await getDatabase();
      
      // Generar ID si no existe
      final sessionWithId = session.id == null
          ? session.copyWith(id: _uuid.v4())
          : session;
      
      // Validar los datos antes de insertar
      final sessionMap = sessionWithId.toMap();
      logger.debug(
        'Insertando sesión: ${sessionMap.toString()}',
        tag: 'ReadingSessionRepository',
      );
      
      // Asegurarse que ningún campo requerido sea nulo
      final bookId = sessionMap['book_id'];
      if (bookId == null || bookId.toString().isEmpty) {
        throw Exception('book_id es nulo o vacío: $bookId');
      }
      
      // Intentar insertar en la base de datos
      await db.insert(
        'reading_sessions',
        sessionMap,
      );
      
      logger.debug(
        'Sesión insertada correctamente con id: ${sessionWithId.id}',
        tag: 'ReadingSessionRepository',
      );
      return sessionWithId;
    } catch (e, stackTrace) {
      logger.error(
        'No se pudo guardar la sesión de lectura',
        error: e,
        stackTrace: stackTrace,
        tag: 'ReadingSessionRepository',
      );
      rethrow; // Re-lanzar el error para manejarlo en el provider
    }
  }

  /// Obtener todas las sesiones de lectura
  Future<List<ReadingSession>> getAllReadingSessions() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('reading_sessions');
    
    return List.generate(maps.length, (i) => ReadingSession.fromMap(maps[i]));
  }

  /// Obtener sesiones de lectura por ID de libro
  Future<List<ReadingSession>> getReadingSessionsByBook(String bookId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_sessions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'start_time DESC',
    );
    
    return List.generate(maps.length, (i) => ReadingSession.fromMap(maps[i]));
  }

  /// Obtener una sesión de lectura por su ID
  Future<ReadingSession?> getReadingSessionById(String id) async {
    final db = await getDatabase();
    
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
    final map = {...maps.first};
    map['notes'] ??= '';
    
    return ReadingSession.fromMap(map);
  }

  /// Actualizar una sesión de lectura
  Future<void> updateReadingSession(ReadingSession session) async {
    final db = await getDatabase();
    
    await db.update(
      'reading_sessions',
      session.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Eliminar una sesión de lectura
  Future<void> deleteReadingSession(String id) async {
    final db = await getDatabase();
    
    await db.delete(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Obtener estadísticas de lectura para un libro específico
  Future<Map<String, dynamic>> getBookReadingStats(String bookId) async {
    final db = await getDatabase();
    
    // Total de sesiones para el libro
    final sessionCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM reading_sessions WHERE book_id = ?',
            [bookId],
    )) ?? 0;
    
    // Tiempo total de lectura (en segundos)
    final totalDurationMinutes =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(duration_minutes) FROM reading_sessions WHERE book_id = ?',
            [bookId],
          ),
        ) ??
        0;
    final totalDuration = totalDurationMinutes * 60; // Convertir minutos a segundos
    
    // Total de páginas leídas
    final totalPages =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(end_page - start_page) FROM reading_sessions WHERE book_id = ?',
            [bookId],
          ),
        ) ??
        0;
    
    // Velocidad promedio (páginas por hora)
    final double avgSpeed = totalDuration > 0
        ? (totalPages * 3600) / totalDuration
        : 0;
    
    return {
      'sessionCount': sessionCount,
      'totalDuration': totalDuration,
      'totalPages': totalPages,
      'averageSpeed': avgSpeed,
    };
  }
  
  /// Obtener estadísticas generales de lectura
  Future<Map<String, int>> getGeneralReadingStats() async {
    final db = await getDatabase();
    
    // Número total de sesiones
    final sessionCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM reading_sessions'),
        ) ??
        0;
    
    // Tiempo total de lectura (en segundos)
    final totalDurationMinutes =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(duration_minutes) FROM reading_sessions',
          ),
        ) ??
        0;
    final totalDuration = totalDurationMinutes * 60; // Convertir minutos a segundos
    
    // Total de páginas leídas
    final totalPages =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(end_page - start_page) FROM reading_sessions',
          ),
        ) ??
        0;
    
    // Número de días con al menos una sesión de lectura
    final readingDays =
        Sqflite.firstIntValue(
          await db.rawQuery('''
        SELECT COUNT(DISTINCT date(start_time/1000, 'unixepoch')) 
        FROM reading_sessions
      '''),
        ) ??
        0;
    
    return {
      'sessionCount': sessionCount,
      'totalDuration': totalDuration,
      'totalPages': totalPages,
      'readingDays': readingDays,
    };
  }
}
