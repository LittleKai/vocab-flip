import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  factory AppDatabase() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create decks table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableDecks} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL DEFAULT 'vi',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        linked_public_deck_id TEXT,
        linked_version INTEGER,
        is_published INTEGER DEFAULT 0,
        published_deck_id TEXT
      )
    ''');

    // Create flashcards table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableFlashcards} (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front TEXT NOT NULL,
        front_phonetic TEXT,
        back TEXT NOT NULL,
        example TEXT,
        notes TEXT,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        easiness_factor REAL NOT NULL DEFAULT 2.5,
        interval INTEGER NOT NULL DEFAULT 0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        next_review_date TEXT,
        last_review_date TEXT,
        FOREIGN KEY (deck_id) REFERENCES ${AppConstants.tableDecks}(id) ON DELETE CASCADE
      )
    ''');

    // Create study sessions table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableStudySessions} (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        cards_studied INTEGER NOT NULL DEFAULT 0,
        cards_correct INTEGER NOT NULL DEFAULT 0,
        cards_incorrect INTEGER NOT NULL DEFAULT 0,
        total_time_seconds INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (deck_id) REFERENCES ${AppConstants.tableDecks}(id) ON DELETE CASCADE
      )
    ''');

    // Create review logs table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableReviewLogs} (
        id TEXT PRIMARY KEY,
        flashcard_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        reviewed_at TEXT NOT NULL,
        quality INTEGER NOT NULL,
        response_time_ms INTEGER NOT NULL DEFAULT 0,
        easiness_factor_before REAL NOT NULL,
        easiness_factor_after REAL NOT NULL,
        interval_before INTEGER NOT NULL,
        interval_after INTEGER NOT NULL,
        FOREIGN KEY (flashcard_id) REFERENCES ${AppConstants.tableFlashcards}(id) ON DELETE CASCADE,
        FOREIGN KEY (session_id) REFERENCES ${AppConstants.tableStudySessions}(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_flashcards_deck_id ON ${AppConstants.tableFlashcards}(deck_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_flashcards_next_review ON ${AppConstants.tableFlashcards}(next_review_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_study_sessions_deck_id ON ${AppConstants.tableStudySessions}(deck_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_review_logs_flashcard_id ON ${AppConstants.tableReviewLogs}(flashcard_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_review_logs_session_id ON ${AppConstants.tableReviewLogs}(session_id)
    ''');

    // Create imported deck links table (for tracking synced public decks)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableImportedDeckLinks} (
        id TEXT PRIMARY KEY,
        public_deck_id TEXT NOT NULL,
        local_deck_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        imported_version INTEGER NOT NULL,
        imported_at TEXT NOT NULL,
        last_synced_at TEXT,
        auto_sync INTEGER DEFAULT 1,
        FOREIGN KEY (local_deck_id) REFERENCES ${AppConstants.tableDecks}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_imported_links_local_deck ON ${AppConstants.tableImportedDeckLinks}(local_deck_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_imported_links_public_deck ON ${AppConstants.tableImportedDeckLinks}(public_deck_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add public library fields to decks table
      await db.execute('ALTER TABLE ${AppConstants.tableDecks} ADD COLUMN linked_public_deck_id TEXT');
      await db.execute('ALTER TABLE ${AppConstants.tableDecks} ADD COLUMN linked_version INTEGER');
      await db.execute('ALTER TABLE ${AppConstants.tableDecks} ADD COLUMN is_published INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ${AppConstants.tableDecks} ADD COLUMN published_deck_id TEXT');

      // Create imported deck links table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableImportedDeckLinks} (
          id TEXT PRIMARY KEY,
          public_deck_id TEXT NOT NULL,
          local_deck_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          imported_version INTEGER NOT NULL,
          imported_at TEXT NOT NULL,
          last_synced_at TEXT,
          auto_sync INTEGER DEFAULT 1,
          FOREIGN KEY (local_deck_id) REFERENCES ${AppConstants.tableDecks}(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_imported_links_local_deck ON ${AppConstants.tableImportedDeckLinks}(local_deck_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_imported_links_public_deck ON ${AppConstants.tableImportedDeckLinks}(public_deck_id)
      ''');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete(AppConstants.tableReviewLogs);
    await db.delete(AppConstants.tableStudySessions);
    await db.delete(AppConstants.tableFlashcards);
    await db.delete(AppConstants.tableDecks);
  }
}
