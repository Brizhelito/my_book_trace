import 'package:flutter/material.dart';
import 'package:my_book_trace/models/book.dart';
import 'package:my_book_trace/repositories/book_repository.dart';
import 'package:my_book_trace/services/preferences_service.dart';

/// Provider para manejar el estado de los libros en la aplicación
class BookProvider extends ChangeNotifier {
  final BookRepository _bookRepository = BookRepository();
  final PreferencesService _preferencesService = PreferencesService();
  
  // Lista de todos los libros
  List<Book> _books = [];
  
  // Libro actualmente seleccionado
  Book? _selectedBook;
  
  // Filtro actual de libros (todos, leyendo, terminados, etc.)
  String _currentFilter = 'all';
  
  // Parámetros de búsqueda avanzada
  String _searchQuery = '';
  String? _filterGenre;
  String? _filterLanguage;
  String? _filterPublisher;
  int? _filterYearStart;
  int? _filterYearEnd;
  String _sortBy = 'title';
  bool _sortAscending = true;
  
  // Getters
  List<Book> get books => _books;
  Book? get selectedBook => _selectedBook;
  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  String? get filterGenre => _filterGenre;
  String? get filterLanguage => _filterLanguage;
  String? get filterPublisher => _filterPublisher;
  int? get filterYearStart => _filterYearStart;
  int? get filterYearEnd => _filterYearEnd;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  
  // Libros filtrados
  List<Book> get filteredBooks {
    if (_currentFilter == 'all') {
      return _books;
    } else {
      return _books.where((book) => book.status == _currentFilter).toList();
    }
  }
  
  // Contador por estado
  int get readingCount => _books.where((book) => book.status == Book.STATUS_IN_PROGRESS).length;
  int get completedCount => _books.where((book) => book.status == Book.STATUS_COMPLETED).length;
  int get notStartedCount => _books.where((book) => book.status == Book.STATUS_NOT_STARTED).length;
  int get abandonedCount => _books.where((book) => book.status == Book.STATUS_ABANDONED).length;
  
  // Inicializar provider
  Future<void> initialize() async {
    await _loadPreferences();
    await loadBooks();
  }
  
  /// Obtiene todos los libros de la base de datos
  Future<List<Book>> getAllBooks() async {
    try {
      return await _bookRepository.getAllBooks();
    } catch (e) {
      debugPrint('Error al obtener todos los libros: $e');
      return [];
    }
  }
  
  // Cargar preferencias guardadas
  Future<void> _loadPreferences() async {
    try {
      // Cargar filtros
      final filterPrefs = await _preferencesService.loadBookFilters();
      if (filterPrefs.isNotEmpty) {
        _searchQuery = filterPrefs['searchQuery'] ?? '';
        _currentFilter = filterPrefs['currentFilter'] ?? 'all';
        _filterGenre = filterPrefs['genre'];
        _filterLanguage = filterPrefs['language'];
        _filterPublisher = filterPrefs['publisher'];
        _filterYearStart = filterPrefs['yearStart'];
        _filterYearEnd = filterPrefs['yearEnd'];
      }
      
      // Cargar ordenación
      final sortingPrefs = await _preferencesService.loadBookSorting();
      if (sortingPrefs.isNotEmpty) {
        _sortBy = sortingPrefs['sortBy'] ?? 'title';
        _sortAscending = sortingPrefs['ascending'] ?? true;
      }
    } catch (e) {
      debugPrint('Error al cargar preferencias: $e');
    }
  }
  
  // Cargar todos los libros desde la base de datos
  Future<void> loadBooks() async {
    try {
      debugPrint('BookProvider: Iniciando carga de libros');
      if (_hasAdvancedFilters()) {
        debugPrint('BookProvider: Aplicando filtros avanzados');
        await _applyAdvancedSearch();
      } else {
        debugPrint('BookProvider: Cargando todos los libros sin filtros');
        _books = await _bookRepository.getAllBooks();
      }
      debugPrint('BookProvider: Libros cargados. Total: ${_books.length}');
      for (var i = 0; i < _books.length; i++) {
        debugPrint('BookProvider: Libro[$i]: ${_books[i].title} (ID: ${_books[i].id})');
      }
      notifyListeners();
      debugPrint('BookProvider: Notificación enviada a listeners');
    } catch (e) {
      debugPrint('BookProvider: ERROR al cargar libros: $e');
      // Manejar error
    }
  }
  
  // Establecer el filtro actual
  void setFilter(String filter) async {
    _currentFilter = filter;
    notifyListeners();
    
    // Guardar preferencia
    await _saveFilterPreferences();
  }
  
  // Seleccionar un libro
  Future<void> selectBook(String bookId) async {
    try {
      _selectedBook = await _bookRepository.getBookById(bookId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al seleccionar libro: $e');
      // Manejar error
    }
  }
  
  // Añadir un libro nuevo
  Future<String?> addBook(Book book) async {
    try {
      debugPrint('BookProvider: Iniciando addBook para libro: ${book.title}');
      final bookId = await _bookRepository.insertBook(book);
      debugPrint('BookProvider: Libro insertado con ID: $bookId');
      
      debugPrint('BookProvider: Recargando lista de libros después de inserción');
      await loadBooks();  // Recargar lista
      
      // Verificar que el libro aparece en la lista actualizada
      final bool encontrado = _books.any((b) => b.id == bookId);
      debugPrint('BookProvider: Verificación - ¿Libro encontrado en lista actualizada?: $encontrado');
      
      return bookId;
    } catch (e) {
      debugPrint('BookProvider: ERROR al añadir libro: $e');
      return null;
    }
  }
  
  // Actualizar un libro existente
  Future<bool> updateBook(Book book) async {
    try {
      debugPrint('BookProvider: Iniciando updateBook para libro: ${book.title} (ID: ${book.id})');
      final result = await _bookRepository.updateBook(book);
      debugPrint('BookProvider: Resultado de actualización: $result filas afectadas');
      
      // Si es el libro seleccionado actualmente, actualizarlo
      if (_selectedBook != null && _selectedBook!.id == book.id) {
        debugPrint('BookProvider: Actualizando libro seleccionado en memoria');
        _selectedBook = book;
      }
      
      debugPrint('BookProvider: Recargando lista de libros después de actualización');
      await loadBooks();  // Recargar lista
      
      // Verificar que el libro aparece en la lista actualizada
      final bool encontrado = _books.any((b) => b.id == book.id);
      debugPrint('BookProvider: Verificación - ¿Libro actualizado encontrado en lista?: $encontrado');
      
      return result > 0;
    } catch (e) {
      debugPrint('BookProvider: ERROR al actualizar libro: $e');
      return false;
    }
  }
  
  // Eliminar un libro
  Future<bool> deleteBook(String bookId) async {
    try {
      await _bookRepository.deleteBook(bookId);
      
      // Si es el libro seleccionado, limpiarlo
      if (_selectedBook != null && _selectedBook!.id == bookId) {
        _selectedBook = null;
      }
      
      await loadBooks();  // Recargar lista
      return true;
    } catch (e) {
      debugPrint('Error al eliminar libro: $e');
      return false;
    }
  }
  
  // Actualizar estado de lectura de un libro
  Future<bool> updateBookStatus(String bookId, String newStatus) async {
    try {
      await _bookRepository.updateBookStatus(bookId, newStatus);
      
      // Actualizar el libro seleccionado si corresponde
      if (_selectedBook != null && _selectedBook!.id == bookId) {
        _selectedBook = _selectedBook!.copyWith(status: newStatus);
      }
      
      await loadBooks();  // Recargar lista
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado de libro: $e');
      return false;
    }
  }
  
  // Buscar libros por texto
  Future<void> searchBooks(String query) async {
    try {
      _searchQuery = query;
      
      if (_hasAdvancedFilters()) {
        await _applyAdvancedSearch();
      } else if (query.isEmpty) {
        await loadBooks();
        return;
      } else {
        _books = await _bookRepository.searchBooks(query);
      }
      
      notifyListeners();
      
      // Guardar preferencia de búsqueda
      await _saveFilterPreferences();
    } catch (e) {
      debugPrint('Error al buscar libros: $e');
      // Manejar error
    }
  }
  
  // Verificar si hay filtros avanzados activos
  bool _hasAdvancedFilters() {
    return _filterGenre != null || 
           _filterLanguage != null || 
           _filterPublisher != null || 
           _filterYearStart != null || 
           _filterYearEnd != null || 
           _sortBy != 'title' || 
           !_sortAscending;
  }
  
  // Aplicar búsqueda avanzada con todos los filtros
  Future<void> _applyAdvancedSearch() async {
    _books = await _bookRepository.advancedSearchBooks(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      status: _currentFilter != 'all' ? _currentFilter : null,
      genre: _filterGenre,
      language: _filterLanguage,
      publisher: _filterPublisher,
      publicationYearStart: _filterYearStart,
      publicationYearEnd: _filterYearEnd,
      sortBy: _sortBy,
      ascending: _sortAscending,
    );
  }
  
  // Establecer filtros de género
  Future<void> setGenreFilter(String? genre) async {
    _filterGenre = genre;
    await loadBooks();
    await _saveFilterPreferences();
  }
  
  // Establecer filtros de idioma
  Future<void> setLanguageFilter(String? language) async {
    _filterLanguage = language;
    await loadBooks();
    await _saveFilterPreferences();
  }
  
  // Establecer filtros de editorial
  Future<void> setPublisherFilter(String? publisher) async {
    _filterPublisher = publisher;
    await loadBooks();
    await _saveFilterPreferences();
  }
  
  // Establecer filtros de año
  Future<void> setYearFilter(int? start, int? end) async {
    _filterYearStart = start;
    _filterYearEnd = end;
    await loadBooks();
    await _saveFilterPreferences();
  }
  
  // Establecer ordenación
  Future<void> setSorting(String sortBy, bool ascending) async {
    _sortBy = sortBy;
    _sortAscending = ascending;
    await loadBooks();
    await _saveSortPreferences();
  }
  
  // Guardar preferencias de filtros
  Future<void> _saveFilterPreferences() async {
    await _preferencesService.saveBookFilters(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      currentFilter: _currentFilter != 'all' ? _currentFilter : null,
      genre: _filterGenre,
      language: _filterLanguage,
      publisher: _filterPublisher,
      yearStart: _filterYearStart,
      yearEnd: _filterYearEnd,
    );
  }
  
  // Guardar preferencias de ordenación
  Future<void> _saveSortPreferences() async {
    await _preferencesService.saveBookSorting(
      sortBy: _sortBy,
      ascending: _sortAscending,
    );
  }
  
  // Limpiar todos los filtros
  Future<void> clearFilters() async {
    _searchQuery = '';
    _filterGenre = null;
    _filterLanguage = null;
    _filterPublisher = null;
    _filterYearStart = null;
    _filterYearEnd = null;
    _sortBy = 'title';
    _sortAscending = true;
    _currentFilter = 'all';
    
    await loadBooks();
    
    // Limpiar preferencias guardadas
    await _preferencesService.clearBookPreferences();
  }
}
