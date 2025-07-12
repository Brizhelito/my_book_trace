/// Constantes para MyBookTrace App
///
/// Este archivo contiene todas las constantes usadas en la aplicación.
library;

// Rutas de la aplicación
class AppRoutes {
  // Rutas principales
  static const String splash = '/';
  static const String home = '/home';
  static const String bookList = '/books';
  static const String bookDetail = '/books/:id';
  static const String addBook = '/books/add';
  static const String editBook = '/books/:id/edit';
  static const String readingSession = '/reading-session/:id';
  static const String activeReadingSession = '/active-reading/:id';
  static const String readingSessionHistory = '/reading-sessions/history';
  static const String statistics = '/statistics';
  static const String challenges = '/challenges';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Rutas anidadas
  static const String bookNotes = 'notes';
  static const String bookStats = 'stats';

  // Funciones para rutas con parámetros
  static String bookDetailPath(String id) => '/books/$id';
  static String editBookPath(String id) => '/books/$id/edit';
  static String readingSessionPath(String id) => '/reading-session/$id';
  static String activeReadingSessionPath(String id) => '/active-reading/$id';
}

// Constantes de la base de datos
class DbConstants {
  /// Constantes para la base de datos
  static const String dbName = 'my_book_trace.db';
  static const int dbVersion =
      4; // Versión actualizada para incluir tabla de desafíos

  // Nombres de tablas
  static const String tableBooks = 'books';
  static const String tableReadingSessions = 'reading_sessions';
  static const String tableReadingStats = 'reading_stats';
  static const String tableChallenges = 'challenges';
  static const String tableNotes = 'notes';
  static const String tableUserPreferences = 'user_preferences';
}

// Constantes de UI
class UiConstants {
  // Espaciado
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double defaultPadding =
      16.0; // Padding predeterminado para uso general

  // Radios
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;

  // Duración de animaciones
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 350);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
}

// Constantes para APIs externas
class ApiConstants {
  static const String googleBooksBaseUrl =
      'https://www.googleapis.com/books/v1/volumes';
  static const String openLibraryBaseUrl = 'https://openlibrary.org/api/books';
}

// Constantes para preferencias de usuario
class PreferenceKeys {
  static const String theme = 'app_theme';
  static const String language = 'app_language';
  static const String userFirstName = 'user_first_name';
  static const String dailyGoal = 'daily_reading_goal';
  static const String weeklyGoal = 'weekly_reading_goal';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String reminderTime = 'reading_reminder_time';
}
