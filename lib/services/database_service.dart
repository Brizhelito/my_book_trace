import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_book_trace/constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Obtiene la instancia de la base de datos, creándola si no existe
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DbConstants.dbName);

    // Crear la base de datos y ejecutar las migraciones
    return await openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas de la base de datos en la primera ejecución
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Tabla de libros
      await txn.execute('''
        CREATE TABLE ${DbConstants.tableBooks} (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          isbn TEXT,
          cover_image_url TEXT,
          description TEXT,
          page_count INTEGER,
          publisher TEXT,
          publication_year INTEGER,
          genre TEXT,
          language TEXT,
          rating REAL,
          start_date TEXT,
          finish_date TEXT,
          status TEXT NOT NULL,
          current_page INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Tabla de sesiones de lectura
      await txn.execute('''
        CREATE TABLE ${DbConstants.tableReadingSessions} (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          start_page INTEGER NOT NULL,
          end_page INTEGER,
          start_time TEXT NOT NULL,
          end_time TEXT,
          duration_minutes INTEGER,
          notes TEXT,
          FOREIGN KEY (book_id) REFERENCES ${DbConstants.tableBooks} (id) ON DELETE CASCADE
        )
      ''');

      // Tabla de estadísticas de lectura
      await txn.execute('''
        CREATE TABLE ${DbConstants.tableReadingStats} (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL DEFAULT 'default_user',
          date TEXT NOT NULL,
          total_pages INTEGER NOT NULL DEFAULT 0,
          total_minutes INTEGER NOT NULL DEFAULT 0,
          books_read INTEGER NOT NULL DEFAULT 0,
          books_completed INTEGER NOT NULL DEFAULT 0,
          UNIQUE(user_id, date)
        )
      ''');

      // Tabla de desafíos
      await txn.execute('''
        CREATE TABLE ${DbConstants.tableChallenges} (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          type INTEGER NOT NULL,
          target INTEGER NOT NULL,
          current_progress INTEGER DEFAULT 0,
          is_completed INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Tabla de notas
      await txn.execute('''
        CREATE TABLE ${DbConstants.tableNotes} (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          page INTEGER,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (book_id) REFERENCES ${DbConstants.tableBooks} (id) ON DELETE CASCADE
        )
      ''');

      // Tabla de preferencias de usuario
      await txn.execute('''
        CREATE TABLE ${DbConstants.tableUserPreferences} (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // Insertar algunas preferencias de usuario por defecto
      await txn.insert(
        DbConstants.tableUserPreferences,
        {'key': PreferenceKeys.theme, 'value': 'system'},
      );
      
      await txn.insert(
        DbConstants.tableUserPreferences,
        {'key': PreferenceKeys.dailyGoal, 'value': '20'},
      );
    });
  }

  /// Maneja las actualizaciones de la base de datos entre versiones
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración a versión 2
      await db.execute('ALTER TABLE ${DbConstants.tableBooks} ADD COLUMN status TEXT DEFAULT \'planning\'');
    }
    
    if (oldVersion < 3) {
      // Migración a versión 3: Añadir campos created_at, updated_at y current_page
      final now = DateTime.now().toIso8601String();
      await db.execute('ALTER TABLE ${DbConstants.tableBooks} ADD COLUMN created_at TEXT DEFAULT \'$now\'');
      await db.execute('ALTER TABLE ${DbConstants.tableBooks} ADD COLUMN updated_at TEXT DEFAULT \'$now\'');
      await db.execute('ALTER TABLE ${DbConstants.tableBooks} ADD COLUMN current_page INTEGER DEFAULT 0');
    }
    
    if (oldVersion < 4) {
      // Migración a versión 4: Añadir tabla de desafíos
      await db.execute('''
        CREATE TABLE ${DbConstants.tableChallenges} (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          type INTEGER NOT NULL,
          target INTEGER NOT NULL,
          current_progress INTEGER DEFAULT 0,
          is_completed INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  /// Cierra la conexión con la base de datos
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
