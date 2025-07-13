/// Modelo de datos para un libro en la aplicación MyBookTrace
///
/// Representa la información completa de un libro, incluyendo todos sus
/// atributos para identificación, seguimiento y visualización.
library;

class Book {
  /// ID único del libro en la base de datos
  final String? id;

  /// Título del libro
  final String title;

  /// Autor(es) del libro
  final String author;

  /// ISBN (International Standard Book Number)
  final String? isbn;

  /// URL o ruta a la imagen de portada del libro
  final String? coverImageUrl;

  /// Breve descripción o sinopsis del libro
  final String? description;

  /// Número total de páginas del libro
  final int? pageCount;

  /// Editorial que publica el libro
  final String? publisher;

  /// Año de publicación
  final int? publicationYear;

  /// Género o categoría principal del libro
  final String? genre;

  /// Idioma del libro
  final String? language;

  /// Calificación personal del libro (1-5)
  final double? rating;

  /// Fecha en que se comenzó a leer el libro
  final DateTime? startDate;

  /// Fecha en que se terminó de leer el libro
  final DateTime? finishDate;

  /// Estado actual de lectura (no iniciado, en progreso, finalizado, abandonado)
  final String status;

  /// Página actual de lectura (para seguimiento de progreso)
  final int? currentPage;

  /// Fecha de creación del registro
  final DateTime createdAt;

  /// Fecha de última actualización del registro
  final DateTime updatedAt;

  /// Notas personales sobre el libro

  /// Constructor
  Book({
    this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.coverImageUrl,
    this.description,
    this.pageCount,
    this.publisher,
    this.publicationYear,
    this.genre,
    this.language,
    this.rating,
    this.startDate,
    this.finishDate,
    this.status = 'no_iniciado',
    this.currentPage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Creación de objeto Book desde un mapa de datos (para base de datos)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String?,
      title: map['title'] as String,
      author: map['author'] as String,
      isbn: map['isbn'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      description: map['description'] as String?,
      pageCount: map['page_count'] as int?,
      publisher: map['publisher'] as String?,
      publicationYear: map['publication_year'] as int?,
      genre: map['genre'] as String?,
      language: map['language'] as String?,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      finishDate: map['finish_date'] != null
          ? DateTime.parse(map['finish_date'] as String)
          : null,
      status: map['status'] as String? ?? 'no_iniciado',
      currentPage: map['current_page'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Conversión de objeto Book a un mapa de datos (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'cover_image_url': coverImageUrl,
      'description': description,
      'page_count': pageCount,
      'publisher': publisher,
      'publication_year': publicationYear,
      'genre': genre,
      'language': language,
      'rating': rating,
      'start_date': startDate?.toIso8601String(),
      'finish_date': finishDate?.toIso8601String(),
      'status': status,
      'current_page': currentPage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crear una copia del libro con algunos campos modificados
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverImageUrl,
    String? description,
    int? pageCount,
    String? publisher,
    int? publicationYear,
    String? genre,
    String? language,
    double? rating,
    DateTime? startDate,
    DateTime? finishDate,
    String? status,
    int? currentPage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      publicationYear: publicationYear ?? this.publicationYear,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      rating: rating ?? this.rating,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Representación en cadena del objeto para debugging
  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author, status: $status}';
  }

  /// Estados disponibles para un libro
  static const String statusNotStarted = 'no_iniciado';
  static const String statusInProgress = 'en_progreso';
  static const String statusCompleted = 'finalizado';
  static const String statusAbandoned = 'abandonado';
}
