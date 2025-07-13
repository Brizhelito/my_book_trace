import 'package:flutter/material.dart';
import 'package:MyBookTrace/models/challenge.dart';
import 'package:MyBookTrace/services/challenge_service.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeService _challengeService = ChallengeService();
  
  List<Challenge> _allChallenges = [];
  List<Challenge> _activeChallenges = [];
  List<Challenge> _monthlyChallenges = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Challenge> get allChallenges => _allChallenges;
  List<Challenge> get activeChallenges => _activeChallenges;
  List<Challenge> get monthlyChallenges => _monthlyChallenges;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filtros adicionales
  List<Challenge> get completedChallenges => 
      _allChallenges.where((challenge) => challenge.isCompleted).toList();
  
  List<Challenge> get pendingChallenges =>
      _activeChallenges.where((challenge) => challenge.isPending).toList();
  
  List<Challenge> get inProgressChallenges =>
      _activeChallenges.where((challenge) => challenge.isInProgress).toList();
  
  List<Challenge> get expiredChallenges =>
      _allChallenges.where((challenge) => challenge.isExpired).toList();
  
  // Inicialización
  Future<void> init() async {
    await refreshChallenges();
  }
  
  // Actualiza las listas de desafíos
  Future<void> refreshChallenges() async {
    _setLoading(true);
    
    try {
      // Cargar todos los desafíos
      _allChallenges = await _challengeService.getAllChallenges();
      
      // Cargar desafíos activos
      _activeChallenges = await _challengeService.getActiveChallenges();
      
      // Cargar desafíos del mes actual
      final now = DateTime.now();
      _monthlyChallenges = await _challengeService.getMonthlyChallenges(
        now.year, 
        now.month
      );
      
      _error = null;
    } catch (e) {
      _error = 'Error al cargar los desafíos: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }
  
  // Carga desafíos por mes específico
  Future<void> loadMonthlyChallenges(int year, int month) async {
    _setLoading(true);
    
    try {
      _monthlyChallenges = await _challengeService.getMonthlyChallenges(year, month);
      _error = null;
    } catch (e) {
      _error = 'Error al cargar los desafíos del mes: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtiene un desafío por ID
  Future<Challenge?> getChallengeById(String id) async {
    try {
      return await _challengeService.getChallengeById(id);
    } catch (e) {
      _error = 'Error al obtener el desafío: ${e.toString()}';
      return null;
    }
  }
  
  // Crea un nuevo desafío
  Future<Challenge?> createChallenge(Challenge challenge) async {
    _setLoading(true);
    
    try {
      final newChallenge = await _challengeService.createChallenge(challenge);
      await refreshChallenges();
      return newChallenge;
    } catch (e) {
      _error = 'Error al crear el desafío: ${e.toString()}';
      _setLoading(false);
      return null;
    }
  }
  
  // Actualiza un desafío existente
  Future<bool> updateChallenge(Challenge challenge) async {
    _setLoading(true);
    
    try {
      await _challengeService.updateChallenge(challenge);
      await refreshChallenges();
      return true;
    } catch (e) {
      _error = 'Error al actualizar el desafío: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }
  
  // Elimina un desafío
  Future<bool> deleteChallenge(String id) async {
    _setLoading(true);
    
    try {
      await _challengeService.deleteChallenge(id);
      await refreshChallenges();
      return true;
    } catch (e) {
      _error = 'Error al eliminar el desafío: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }
  
  // Actualiza el progreso de un desafío
  Future<bool> updateProgress(String id, int progress) async {
    try {
      await _challengeService.updateChallengeProgress(id, progress);
      
      // Actualizar el desafío en las listas locales
      _updateChallengeInLists(id, (challenge) {
        return challenge.copyWith(currentProgress: progress);
      });
      
      // Comprobar si el desafío se ha completado
      final challenge = _findChallengeById(id);
      if (challenge != null && !challenge.isCompleted && progress >= challenge.target) {
        await completeChallenge(id);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar el progreso: ${e.toString()}';
      return false;
    }
  }
  
  // Marca un desafío como completado
  Future<bool> completeChallenge(String id) async {
    try {
      await _challengeService.completeChallenge(id);
      
      // Actualizar el desafío en las listas locales
      _updateChallengeInLists(id, (challenge) {
        return challenge.copyWith(isCompleted: true);
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al completar el desafío: ${e.toString()}';
      return false;
    }
  }
  
  // Desactiva un desafío
  Future<bool> deactivateChallenge(String id) async {
    try {
      await _challengeService.deactivateChallenge(id);
      
      // Actualizar el desafío en las listas locales
      _updateChallengeInLists(id, (challenge) {
        return challenge.copyWith(isActive: false);
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al desactivar el desafío: ${e.toString()}';
      return false;
    }
  }
  
  // Valida las fechas de un desafío
  bool validateChallengeDates(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    
    // Las fechas no pueden ser del pasado
    if (startDate.isBefore(now) && startDate.day != now.day) {
      _error = 'La fecha de inicio no puede ser en el pasado';
      return false;
    }
    
    // La fecha de fin debe ser posterior a la de inicio
    if (endDate.isBefore(startDate)) {
      _error = 'La fecha de fin debe ser posterior a la fecha de inicio';
      return false;
    }
    
    return true;
  }
  
  // Métodos de utilidad privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Encuentra un desafío por ID en las listas locales
  Challenge? _findChallengeById(String id) {
    try {
      return _allChallenges.firstWhere((challenge) => challenge.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Actualiza un desafío en todas las listas locales
  void _updateChallengeInLists(String id, Challenge Function(Challenge) updateFn) {
    _allChallenges = _updateChallengeInList(_allChallenges, id, updateFn);
    _activeChallenges = _updateChallengeInList(_activeChallenges, id, updateFn);
    _monthlyChallenges = _updateChallengeInList(_monthlyChallenges, id, updateFn);
  }
  
  // Actualiza un desafío en una lista específica
  List<Challenge> _updateChallengeInList(
    List<Challenge> list, 
    String id, 
    Challenge Function(Challenge) updateFn
  ) {
    return list.map((challenge) {
      if (challenge.id == id) {
        return updateFn(challenge);
      }
      return challenge;
    }).toList();
  }
}
