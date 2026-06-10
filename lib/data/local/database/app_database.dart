import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
    debugPrint('AppDatabase: Initializing database...');

    // Use Documents folder for user data on all platforms
    // This ensures data is NOT deleted when app is updated
    final String databasesPath;
    if (kIsWeb) {
      debugPrint('AppDatabase: Using default database path for web platform');
      databasesPath = await getDatabasesPath();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('AppDatabase: Using sqflite_ffi for desktop platform');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // Desktop: use Documents/vocabflip folder
      final documentsDir = await getApplicationDocumentsDirectory();
      databasesPath = join(documentsDir.path, 'vocabflip');
      // Create directory if it doesn't exist
      final dir = Directory(databasesPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Migrate old database from app installation directory (if exists)
      await _migrateOldDatabase(databasesPath);
    } else {
      // Mobile: use default database path
      databasesPath = await getDatabasesPath();
    }

    final path = join(databasesPath, AppConstants.databaseName);
    debugPrint('AppDatabase: Database path: $path');

    try {
      final db = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      debugPrint('AppDatabase: Database opened successfully, version: ${AppConstants.databaseVersion}');
      return db;
    } catch (e, stackTrace) {
      debugPrint('AppDatabase: Error opening database: $e');
      debugPrint('AppDatabase: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('AppDatabase: Creating database tables (version: $version)...');
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
        published_deck_id TEXT,
        was_imported INTEGER DEFAULT 0,
        show_back_first INTEGER DEFAULT 0,
        front_fields TEXT DEFAULT 'word,phonetic',
        back_fields TEXT DEFAULT 'meaning,example,notes',
        image_display_mode TEXT DEFAULT 'both',
        image_path TEXT,
        auto_play_tts_on_flip INTEGER DEFAULT 1,
        category TEXT,
        tags TEXT
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
        image_url TEXT,
        front_image_url TEXT,
        back_image_url TEXT,
        share_image INTEGER DEFAULT 1,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        easiness_factor REAL NOT NULL DEFAULT 2.5,
        interval INTEGER NOT NULL DEFAULT 0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        stability REAL,
        difficulty REAL,
        fsrs_state INTEGER,
        fsrs_step INTEGER,
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

    // Create sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)
    ''');
  }

  /// Safely add a column to a table, ignoring if it already exists
  Future<void> _safeAddColumn(Database db, String table, String columnDef) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDef');
    } catch (e) {
      if (e.toString().contains('duplicate column')) {
        debugPrint('AppDatabase: Column already exists, skipping: $columnDef');
      } else {
        rethrow;
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('AppDatabase: Upgrading database from v$oldVersion to v$newVersion');

    // Handle database migrations here
    if (oldVersion < 2) {
      debugPrint('AppDatabase: Applying migration v1 -> v2');
      // Add public library fields to decks table
      await _safeAddColumn(db, AppConstants.tableDecks, 'linked_public_deck_id TEXT');
      await _safeAddColumn(db, AppConstants.tableDecks, 'linked_version INTEGER');
      await _safeAddColumn(db, AppConstants.tableDecks, 'is_published INTEGER DEFAULT 0');
      await _safeAddColumn(db, AppConstants.tableDecks, 'published_deck_id TEXT');

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

    if (oldVersion < 3) {
      debugPrint('AppDatabase: Applying migration v2 -> v3 (adding image_url to flashcards)');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'image_url TEXT');
    }

    if (oldVersion < 4) {
      debugPrint('AppDatabase: Applying migration v3 -> v4 (adding front/back image support)');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'front_image_url TEXT');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'back_image_url TEXT');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'share_image INTEGER DEFAULT 1');
    }

    if (oldVersion < 5) {
      debugPrint('AppDatabase: Applying migration v4 -> v5 (adding show_back_first to decks)');
      await _safeAddColumn(db, AppConstants.tableDecks, 'show_back_first INTEGER DEFAULT 0');
    }

    if (oldVersion < 6) {
      debugPrint('AppDatabase: Applying migration v5 -> v6 (adding card structure to decks)');
      await _safeAddColumn(db, AppConstants.tableDecks, "front_fields TEXT DEFAULT 'word,phonetic'");
      await _safeAddColumn(db, AppConstants.tableDecks, "back_fields TEXT DEFAULT 'meaning,example,notes'");
      await _safeAddColumn(db, AppConstants.tableDecks, "image_display_mode TEXT DEFAULT 'both'");
    }

    if (oldVersion < 7) {
      debugPrint('AppDatabase: Applying migration v6 -> v7 (adding auto_play_tts_on_flip to decks)');
      await _safeAddColumn(db, AppConstants.tableDecks, 'auto_play_tts_on_flip INTEGER DEFAULT 1');
    }

    if (oldVersion < 8) {
      debugPrint('AppDatabase: Applying migration v7 -> v8 (adding image_path to decks)');
      await _safeAddColumn(db, AppConstants.tableDecks, 'image_path TEXT');
    }

    if (oldVersion < 9) {
      debugPrint('AppDatabase: Applying migration v8 -> v9 (adding category and tags to decks)');
      await _safeAddColumn(db, AppConstants.tableDecks, 'category TEXT');
      await _safeAddColumn(db, AppConstants.tableDecks, 'tags TEXT');
    }

    if (oldVersion < 10) {
      debugPrint('AppDatabase: Applying migration v9 -> v10 (adding was_imported to decks)');
      await _safeAddColumn(db, AppConstants.tableDecks, 'was_imported INTEGER DEFAULT 0');
      // Mark existing linked decks as was_imported
      await db.execute('UPDATE ${AppConstants.tableDecks} SET was_imported = 1 WHERE linked_public_deck_id IS NOT NULL');
    }

    if (oldVersion < 11) {
      debugPrint('AppDatabase: Applying migration v10 -> v11 (adding lapses to flashcards)');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'lapses INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 12) {
      debugPrint('AppDatabase: Applying migration v11 -> v12 (adding sync_queue table)');
      await db.execute('''
        CREATE TABLE sync_queue (
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 13) {
      debugPrint('AppDatabase: Applying migration v12 -> v13 (FSRS: adding stability and difficulty to flashcards)');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'stability REAL');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'difficulty REAL');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'fsrs_state INTEGER');
      await _safeAddColumn(db, AppConstants.tableFlashcards, 'fsrs_step INTEGER');
      
      // Convert SM-2 to FSRS for existing cards
      // S ≈ interval
      // D ≈ 10 - ((EF - 1.3) * (5.0 / 1.2)) clamped to [1, 10]
      await db.execute('''
        UPDATE ${AppConstants.tableFlashcards}
        SET 
          stability = interval,
          difficulty = MAX(1.0, MIN(10.0, 10.0 - ((easiness_factor - 1.3) * 4.16))),
          fsrs_state = 2, /* State.review */
          fsrs_step = 0
        WHERE repetitions > 0 AND stability IS NULL
      ''');
    }
  }

  /// Migrate database from old location (app installation directory) to new location (Documents folder)
  /// This ensures user data is preserved when updating the app
  Future<void> _migrateOldDatabase(String newDatabasesPath) async {
    try {
      final newDbPath = join(newDatabasesPath, AppConstants.databaseName);
      final newDbFile = File(newDbPath);

      // If new database already exists, no need to migrate
      if (newDbFile.existsSync()) {
        debugPrint('AppDatabase: New database already exists, skipping migration');
        return;
      }

      // Find old database in app installation directory
      // On Windows, this is typically where the .exe is located
      final exePath = Platform.resolvedExecutable;
      final appDir = dirname(exePath);

      // Check multiple possible old locations
      final possibleOldPaths = [
        join(appDir, AppConstants.databaseName),
        join(appDir, 'data', AppConstants.databaseName),
        join(appDir, 'databases', AppConstants.databaseName),
      ];

      File? oldDbFile;
      for (final oldPath in possibleOldPaths) {
        final file = File(oldPath);
        if (file.existsSync()) {
          oldDbFile = file;
          debugPrint('AppDatabase: Found old database at: $oldPath');
          break;
        }
      }

      if (oldDbFile == null) {
        debugPrint('AppDatabase: No old database found to migrate');
        return;
      }

      // Copy old database to new location
      debugPrint('AppDatabase: Migrating database to: $newDbPath');
      await oldDbFile.copy(newDbPath);
      debugPrint('AppDatabase: Database migration completed successfully!');

      // Also migrate flashcard_images folder if it exists
      await _migrateOldImages(appDir, dirname(newDatabasesPath));

      // Delete old database after successful migration (optional - keep as backup)
      // await oldDbFile.delete();
      // debugPrint('AppDatabase: Old database deleted');

    } catch (e) {
      debugPrint('AppDatabase: Error during migration: $e');
      // Don't rethrow - migration failure shouldn't prevent app from starting
      // A new database will be created instead
    }
  }

  /// Migrate old flashcard images from app directory to Documents folder
  Future<void> _migrateOldImages(String appDir, String documentsDir) async {
    try {
      final oldImagesDir = Directory(join(appDir, 'flashcard_images'));
      if (!oldImagesDir.existsSync()) {
        debugPrint('AppDatabase: No old images folder found');
        return;
      }

      final newImagesDir = Directory(join(documentsDir, 'flashcard_images'));
      if (!newImagesDir.existsSync()) {
        await newImagesDir.create(recursive: true);
      }

      debugPrint('AppDatabase: Migrating images from ${oldImagesDir.path}');

      final imageFiles = oldImagesDir.listSync();
      int migratedCount = 0;

      for (final entity in imageFiles) {
        if (entity is File) {
          final fileName = basename(entity.path);
          final newPath = join(newImagesDir.path, fileName);
          final newFile = File(newPath);

          // Only copy if doesn't already exist in new location
          if (!newFile.existsSync()) {
            await entity.copy(newPath);
            migratedCount++;
          }
        }
      }

      debugPrint('AppDatabase: Migrated $migratedCount images');

    } catch (e) {
      debugPrint('AppDatabase: Error migrating images: $e');
      // Don't rethrow - image migration failure is not critical
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
