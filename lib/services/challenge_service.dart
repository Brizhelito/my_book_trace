import 'package:my_book_trace/models/challenge.dart';
import 'package:my_book_trace/services/database_service.dart';
import 'package:my_book_trace/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class ChallengeService {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = Uuid();
  
  /// Obtiene todos los desafíos
  Future<List<Challenge>> getAllChallenges() async {
    final db = await _dbService.database;
    final challenges = await db.query(DbConstants.tableChallenges);
    return challenges.map((e) => Challenge.fromMap(e)).toList();
  }
  
  /// Obtiene todos los desafíos activos
  Future<List<Challenge>> getActiveChallenges() async {
    final db = await _dbService.database;
    final challenges = await db.query(
      DbConstants.tableChallenges,
      where: 'is_active = ?',
      whereArgs: [1]
    );
    return challenges.map((e) => Challenge.fromMap(e)).toList();
  }
  
  /// Obtiene los desafíos activos en un rango de fechas
  Future<List<Challenge>> getChallengesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbService.database;
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    
    final challenges = await db.query(
      DbConstants.tableChallenges,
      where: 'start_date <= ? AND end_date >= ? AND is_active = ?',
      whereArgs: [end, start, 1]
    );
    
    return challenges.map((e) => Challenge.fromMap(e)).toList();
  }
  
  /// Obtiene desafíos mensuales para un mes específico
  Future<List<Challenge>> getMonthlyChallenges(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);  // Último día del mes
    
    return getChallengesByDateRange(startDate, endDate);
  }
  
  /// Obtiene un desafío por su ID
  Future<Challenge?> getChallengeById(String id) async {
    final db = await _dbService.database;
    final challenges = await db.query(
      DbConstants.tableChallenges,
      where: 'id = ?',
      whereArgs: [id]
    );
    
    if (challenges.isEmpty) {
      return null;
    }
    
    return Challenge.fromMap(challenges.first);
  }
  
  /// Crea un nuevo desafío
  Future<Challenge> createChallenge(Challenge challenge) async {
    final db = await _dbService.database;
    
    // Generar ID si no tiene uno
    final newChallenge = challenge.id == null || challenge.id!.isEmpty
        ? challenge.copyWith(
            id: _uuid.v4(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now())
        : challenge;
    
    await db.insert(
      DbConstants.tableChallenges,
      newChallenge.toMap(),
    );
    
    return newChallenge;
  }
  
  /// Actualiza un desafío existente
  Future<int> updateChallenge(Challenge challenge) async {
    final db = await _dbService.database;
    
    // Actualizar fecha de modificación
    final updatedChallenge = challenge.copyWith(
      updatedAt: DateTime.now()
    );
    
    return await db.update(
      DbConstants.tableChallenges,
      updatedChallenge.toMap(),
      where: 'id = ?',
      whereArgs: [challenge.id]
    );
  }
  
  /// Elimina un desafío
  Future<int> deleteChallenge(String id) async {
    final db = await _dbService.database;
    
    return await db.delete(
      DbConstants.tableChallenges,
      where: 'id = ?',
      whereArgs: [id]
    );
  }
  
  /// Actualiza el progreso de un desafío
  Future<int> updateChallengeProgress(String id, int progress) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      DbConstants.tableChallenges,
      {
        'current_progress': progress,
        'updated_at': now
      },
      where: 'id = ?',
      whereArgs: [id]
    );
  }
  
  /// Marca un desafío como completado
  Future<int> completeChallenge(String id) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      DbConstants.tableChallenges,
      {
        'is_completed': 1,
        'updated_at': now
      },
      where: 'id = ?',
      whereArgs: [id]
    );
  }
  
  /// Desactiva un desafío
  Future<int> deactivateChallenge(String id) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      DbConstants.tableChallenges,
      {
        'is_active': 0,
        'updated_at': now
      },
      where: 'id = ?',
      whereArgs: [id]
    );
  }
}
