/// Modelo para representar una sesión de lectura
class ReadingSession {
  final String? id;
  final String bookId;
  final DateTime date;
  final int startPage;
  final int endPage;
  final Duration duration; // Usando Duration en lugar de int
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReadingSession({
    this.id,
    required this.bookId,
    required this.date,
    required this.startPage,
    required this.endPage,
    required this.duration,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  // Constructor adicional para mantener compatibilidad con código existente
  factory ReadingSession.fromSeconds({
    String? id,
    required String bookId,
    required DateTime date,
    required int startPage,
    required int endPage,
    required int durationSeconds,
    String notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingSession(
      id: id,
      bookId: bookId,
      date: date,
      startPage: startPage,
      endPage: endPage,
      duration: Duration(seconds: durationSeconds),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Crear una copia con parámetros modificados
  ReadingSession copyWith({
    String? id,
    String? bookId,
    DateTime? date,
    int? startPage,
    int? endPage,
    Duration? duration,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      date: date ?? this.date,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir a Map para guardar en BD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'start_page': startPage,
      'end_page': endPage,
      'start_time': date.toIso8601String(),  // La fecha en formato ISO
      'end_time': date.add(duration).toIso8601String(),
      'duration_minutes': (duration.inSeconds / 60).ceil(),  // Convertir a minutos para la BD
      'notes': notes,
    };
  }

  // Crear instancia desde Map (ej: desde BD)
  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    final DateTime startTime = DateTime.parse(map['start_time']);
    final DateTime endTime = map['end_time'] != null 
        ? DateTime.parse(map['end_time']) 
        : startTime.add(Duration(minutes: map['duration_minutes'] ?? 0));
    
    // Calculamos la duración como objeto Duration
    final Duration sessionDuration = endTime.difference(startTime);
    
    return ReadingSession(
      id: map['id'],
      bookId: map['book_id'],
      date: startTime,  // Usando start_time como la fecha
      startPage: map['start_page'],
      endPage: map['end_page'],
      duration: sessionDuration,
      notes: map['notes'] ?? '',
      // Estos campos no existen en la tabla, pero necesitamos valores
      createdAt: startTime,  // Usamos start_time como referencia
      updatedAt: endTime,    // Usamos end_time como referencia
    );
  }

  // Obtener el número de páginas leídas
  int get pagesRead => endPage - startPage;

  // Obtener la velocidad de lectura (páginas por hora)
  double get readingSpeed {
    if (duration.inSeconds <= 0) return 0;
    return (pagesRead * 3600) / duration.inSeconds; // páginas por hora
  }
  
  // Obtener la duración en segundos (para compatibilidad con código existente)
  int get durationInSeconds => duration.inSeconds;
  
  // Obtener la duración en minutos (para mostrarlo en la UI)
  int get durationInMinutes => duration.inMinutes;
  
  // Obtener una representación formateada de la duración (HH:MM:SS)
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  String toString() {
    return 'ReadingSession{id: $id, bookId: $bookId, date: $date, startPage: $startPage, endPage: $endPage, duration: ${formattedDuration}, pages: $pagesRead}';
  }
}
