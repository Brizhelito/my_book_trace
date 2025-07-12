// Modelo para desafíos de lectura

/// Modelo para representar un desafío de lectura
class Challenge {
  final String? id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeType type;
  final int target; // Objetivo (páginas, libros, minutos, etc.)
  final int currentProgress; // Progreso actual
  final bool isCompleted;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Constructor del modelo Challenge
  Challenge({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.target,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Crea una copia del desafío con los campos especificados actualizados
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeType? type,
    int? target,
    int? currentProgress,
    bool? isCompleted,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      target: target ?? this.target,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convierte el desafío a un mapa para almacenamiento en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'type': type.index,
      'target': target,
      'current_progress': currentProgress,
      'is_completed': isCompleted ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea un desafío a partir de un mapa de la base de datos
  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      type: ChallengeType.values[map['type']],
      target: map['target'],
      currentProgress: map['current_progress'],
      isCompleted: map['is_completed'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Calcula el porcentaje de progreso del desafío
  double get progressPercentage {
    if (target == 0) return 0.0;
    double percentage = (currentProgress / target) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  /// Verifica si el desafío está vencido
  bool get isExpired {
    return DateTime.now().isAfter(endDate) && !isCompleted;
  }

  /// Verifica si el desafío está en curso
  bool get isInProgress {
    final now = DateTime.now();
    return isActive && !isCompleted && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Verifica si el desafío está pendiente (aún no ha comenzado)
  bool get isPending {
    return isActive && DateTime.now().isBefore(startDate);
  }

  /// Calcula los días restantes hasta que finalice el desafío
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Calcula la duración total del desafío en días
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Devuelve una representación de texto del desafío
  @override
  String toString() {
    return 'Challenge(id: $id, title: $title, type: $type, progress: $currentProgress/$target, isCompleted: $isCompleted)';
  }
}

/// Tipos de desafíos disponibles
enum ChallengeType {
  pages, // Número de páginas leídas
  books, // Número de libros completados
  time,  // Tiempo total de lectura (en minutos)
  streak, // Días consecutivos de lectura
  custom, // Personalizado
}

/// Extensión para obtener representaciones legibles de los tipos de desafíos
extension ChallengeTypeExtension on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.pages:
        return 'Páginas';
      case ChallengeType.books:
        return 'Libros';
      case ChallengeType.time:
        return 'Tiempo';
      case ChallengeType.streak:
        return 'Racha';
      case ChallengeType.custom:
        return 'Personalizado';
    }
  }

  String get unit {
    switch (this) {
      case ChallengeType.pages:
        return 'páginas';
      case ChallengeType.books:
        return 'libros';
      case ChallengeType.time:
        return 'minutos';
      case ChallengeType.streak:
        return 'días';
      case ChallengeType.custom:
        return 'unidades';
    }
  }
}
