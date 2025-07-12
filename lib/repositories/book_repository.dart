import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:my_book_trace/constants/app_constants.dart';
import 'package:my_book_trace/models/book.dart';
import 'package:my_book_trace/services/database_service.dart';

/// Repositorio para manejar todas las operaciones relacionadas con libros
class BookRepository {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  /// Obtener todos los libros
  Future<List<Book>> getAllBooks() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableBooks,
    );

    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  /// Obtener libros por estado
  Future<List<Book>> getBooksByStatus(String status) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableBooks,
      where: 'status = ?',
      whereArgs: [status],
    );

    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  /// Buscar libros por título o autor
  Future<List<Book>> searchBooks(String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableBooks,
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  /// Búsqueda avanzada de libros con múltiples criterios de filtrado
  Future<List<Book>> advancedSearchBooks({
    String? query,
    String? status,
    String? genre,
    String? language,
    String? publisher,
    int? publicationYearStart,
    int? publicationYearEnd,
    String? sortBy,
    bool ascending = true,
  }) async {
    final db = await _databaseService.database;

    // Construir la consulta WHERE de forma dinámica
    final List<String> whereConditions = [];
    final List<dynamic> whereArgs = [];

    // Filtro por texto (busca en título, autor y descripción)
    if (query != null && query.isNotEmpty) {
      whereConditions.add(
        '(title LIKE ? OR author LIKE ? OR description LIKE ?)',
      );
      whereArgs.addAll(['%$query%', '%$query%', '%$query%']);
    }

    // Filtro por estado
    if (status != null && status.isNotEmpty && status != 'all') {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    // Filtro por género
    if (genre != null && genre.isNotEmpty) {
      whereConditions.add('genre LIKE ?');
      whereArgs.add('%$genre%');
    }

    // Filtro por idioma
    if (language != null && language.isNotEmpty) {
      whereConditions.add('language = ?');
      whereArgs.add(language);
    }

    // Filtro por editorial
    if (publisher != null && publisher.isNotEmpty) {
      whereConditions.add('publisher LIKE ?');
      whereArgs.add('%$publisher%');
    }

    // Filtro por rango de años de publicación
    if (publicationYearStart != null) {
      whereConditions.add('publication_year >= ?');
      whereArgs.add(publicationYearStart);
    }

    if (publicationYearEnd != null) {
      whereConditions.add('publication_year <= ?');
      whereArgs.add(publicationYearEnd);
    }

    // Construir la cláusula WHERE completa
    String? whereClause;
    if (whereConditions.isNotEmpty) {
      whereClause = whereConditions.join(' AND ');
    }

    // Configurar la ordenación
    String? orderByClause;
    if (sortBy != null && sortBy.isNotEmpty) {
      // Mapear los criterios de ordenación a columnas reales de la base de datos
      final Map<String, String> orderByMap = {
        'title': 'title',
        'author': 'author',
        'added': 'created_at',
        'updated': 'updated_at',
        'rating': 'rating',
        'pages': 'page_count',
        'year': 'publication_year',
      };

      final dbField = orderByMap[sortBy] ?? 'title';
      orderByClause = '$dbField ${ascending ? 'ASC' : 'DESC'}';
    }

    // Ejecutar la consulta
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableBooks,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderByClause,
    );

    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  /// Obtener un libro por su ID
  Future<Book?> getBookById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableBooks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Book.fromMap(maps.first);
    }

    return null;
  }

  /// Obtener un libro por su ISBN
  Future<Book?> getBookByIsbn(String isbn) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableBooks,
      where: 'isbn = ?',
      whereArgs: [isbn],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Book.fromMap(maps.first);
    }

    return null;
  }

  /// Insertar un nuevo libro
  Future<String> insertBook(Book book) async {
    try {
      print('BookRepository: Iniciando insertBook para libro: ${book.title}');
      final db = await _databaseService.database;
      final String id = _uuid.v4();

      // Crear una copia del libro con el ID generado
      final bookWithId = book.copyWith(id: id);

      // Log del mapa de datos
      final bookMap = bookWithId.toMap();
      print('BookRepository: Datos a insertar: $bookMap');

      // Insertar en la base de datos
      await db.insert(
        DbConstants.tableBooks,
        bookMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('BookRepository: Libro insertado correctamente con ID: $id');

      // Verificar que el libro se insertó correctamente
      final List<Map<String, dynamic>> verificacion = await db.query(
        DbConstants.tableBooks,
        where: 'id = ?',
        whereArgs: [id],
      );

      print(
        'BookRepository: Verificación de inserción: ${verificacion.isNotEmpty ? "Éxito" : "Fallo"}',
      );
      if (verificacion.isNotEmpty) {
        print('BookRepository: Datos recuperados: ${verificacion.first}');
      }

      return id;
    } catch (e) {
      print('BookRepository: ERROR en insertBook: $e');
      rethrow;
    }
  }

  /// Actualizar un libro existente
  Future<int> updateBook(Book book) async {
    try {
      print(
        'BookRepository: Iniciando updateBook para libro: ${book.title} (ID: ${book.id})',
      );
      final db = await _databaseService.database;

      // Log del mapa de datos
      final bookMap = book.toMap();
      print('BookRepository: Datos a actualizar: $bookMap');

      final int result = await db.update(
        DbConstants.tableBooks,
        bookMap,
        where: 'id = ?',
        whereArgs: [book.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('BookRepository: Libro actualizado. Filas afectadas: $result');

      // Verificar que el libro se actualizó correctamente
      final List<Map<String, dynamic>> verificacion = await db.query(
        DbConstants.tableBooks,
        where: 'id = ?',
        whereArgs: [book.id],
      );

      print(
        'BookRepository: Verificación de actualización: ${verificacion.isNotEmpty ? "Éxito" : "Fallo"}',
      );
      if (verificacion.isNotEmpty) {
        print('BookRepository: Datos actualizados: ${verificacion.first}');
      }

      return result;
    } catch (e) {
      print('BookRepository: ERROR en updateBook: $e');
      rethrow;
    }
  }

  /// Eliminar un libro
  Future<int> deleteBook(String id) async {
    final db = await _databaseService.database;

    return await db.delete(
      DbConstants.tableBooks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtener el conteo total de libros
  Future<int> getTotalBookCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableBooks}',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtener el conteo de libros por estado
  Future<Map<String, int>> getBookCountByStatus() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM ${DbConstants.tableBooks} 
      GROUP BY status
    ''');

    final Map<String, int> countByStatus = {
      Book.STATUS_NOT_STARTED: 0,
      Book.STATUS_IN_PROGRESS: 0,
      Book.STATUS_COMPLETED: 0,
      Book.STATUS_ABANDONED: 0,
    };

    for (var row in result) {
      final status = row['status'] as String;
      final count = row['count'] as int;
      countByStatus[status] = count;
    }

    return countByStatus;
  }

  /// Actualizar el estado de un libro
  Future<int> updateBookStatus(String id, String status) async {
    final db = await _databaseService.database;

    return await db.update(
      DbConstants.tableBooks,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
