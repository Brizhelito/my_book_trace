import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar las preferencias del usuario
class PreferencesService {
  // Claves para almacenar preferencias
  static const String _keyBookFilters = 'book_filters';
  static const String _keyBookSorting = 'book_sorting';
  
  /// Guardar filtros de libros
  Future<void> saveBookFilters({
    String? searchQuery,
    String? currentFilter,
    String? genre,
    String? language,
    String? publisher,
    int? yearStart,
    int? yearEnd,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, dynamic> filters = {
      'searchQuery': searchQuery,
      'currentFilter': currentFilter,
      'genre': genre,
      'language': language,
      'publisher': publisher,
      'yearStart': yearStart,
      'yearEnd': yearEnd,
    };
    
    await prefs.setString(_keyBookFilters, jsonEncode(filters));
  }
  
  /// Cargar filtros de libros
  Future<Map<String, dynamic>> loadBookFilters() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? filtersJson = prefs.getString(_keyBookFilters);
    if (filtersJson == null) {
      return {};
    }
    
    return jsonDecode(filtersJson) as Map<String, dynamic>;
  }
  
  /// Guardar preferencias de ordenación
  Future<void> saveBookSorting({
    required String sortBy,
    required bool ascending,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, dynamic> sorting = {
      'sortBy': sortBy,
      'ascending': ascending,
    };
    
    await prefs.setString(_keyBookSorting, jsonEncode(sorting));
  }
  
  /// Cargar preferencias de ordenación
  Future<Map<String, dynamic>> loadBookSorting() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? sortingJson = prefs.getString(_keyBookSorting);
    if (sortingJson == null) {
      return {
        'sortBy': 'title',
        'ascending': true,
      };
    }
    
    return jsonDecode(sortingJson) as Map<String, dynamic>;
  }
  
  /// Limpiar todas las preferencias de búsqueda y filtros
  Future<void> clearBookPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_keyBookFilters);
    await prefs.remove(_keyBookSorting);
  }
}
