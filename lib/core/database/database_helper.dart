import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String dbName = 'poker_tracker.db';
  static const int dbVersion = 2;

  // Table names
  static const String tableGames = 'games';
  static const String tablePlayers = 'players';
  static const String tableTransactions = 'transactions';
  static const String tableTeams = 'teams';
  static const String tableTeamPlayers = 'team_players';

  // Singleton pattern
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('Initializing database...'); // Debug log
      final String path = join(await getDatabasesPath(), dbName);

      return await openDatabase(
        path,
        version: dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // Verify tables exist when database is opened
          await _verifyTables(db);
        },
      );
    } catch (e) {
      print('Error initializing database: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> _verifyTables(Database db) async {
    // Check if tables exist by querying sqlite_master
    final tables = await db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);

    final tableNames = tables.map((t) => t['name'] as String).toList();

    // Verify all required tables exist
    final requiredTables = [
      tableGames,
      tablePlayers,
      tableTransactions,
      tableTeams,
      tableTeamPlayers
    ];

    for (final table in requiredTables) {
      if (!tableNames.contains(table)) {
        throw Exception('Database schema is incomplete. Missing table: $table');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.transaction((txn) async {
        // Create teams table first since it's referenced by team_players
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS $tableTeams (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdBy TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            userId TEXT NOT NULL,
            UNIQUE(name, userId)
          )
        ''');

        await txn.execute('''
          CREATE TABLE IF NOT EXISTS $tableTeamPlayers (
            id TEXT PRIMARY KEY,
            teamId TEXT NOT NULL,
            name TEXT NOT NULL,
            FOREIGN KEY (teamId) REFERENCES $tableTeams (id) ON DELETE CASCADE
          )
        ''');

        // Create other tables
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS $tableGames (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            date TEXT NOT NULL,
            isActive INTEGER NOT NULL,
            createdBy TEXT NOT NULL,
            buyInAmount REAL NOT NULL,
            cutPercentage REAL NOT NULL,
            createdAt TEXT NOT NULL,
            endedAt TEXT,
            userId TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE IF NOT EXISTS $tablePlayers (
            id TEXT NOT NULL,
            gameId TEXT NOT NULL,
            name TEXT NOT NULL,
            buyIns INTEGER NOT NULL DEFAULT 1,
            loans REAL NOT NULL DEFAULT 0,
            cashOut REAL,
            isSettled INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (gameId) REFERENCES $tableGames (id) ON DELETE CASCADE,
            UNIQUE(id, gameId)
          )
        ''');

        await txn.execute('''
          CREATE TABLE IF NOT EXISTS $tableTransactions (
            id TEXT PRIMARY KEY,
            gameId TEXT NOT NULL,
            playerId TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            timestamp TEXT NOT NULL,
            note TEXT,
            relatedPlayerId TEXT,
            isReverted INTEGER NOT NULL DEFAULT 0,
            revertedBy TEXT,
            revertedAt TEXT,
            FOREIGN KEY (gameId) REFERENCES $tableGames (id) ON DELETE CASCADE,
            FOREIGN KEY (playerId, gameId) REFERENCES $tablePlayers (id, gameId) ON DELETE CASCADE
          )
        ''');

        // Create indexes
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_games_userId ON $tableGames (userId)');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_games_isActive ON $tableGames (isActive)');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_players_gameId ON $tablePlayers (gameId)');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_players_composite ON $tablePlayers (id, gameId)');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_transactions_gameId ON $tableTransactions (gameId)');
      });
    } catch (e) {
      print('Error in onCreate: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await db.transaction((txn) async {
          // Backup existing data
          final players = await txn.query(tablePlayers);

          // Drop and recreate players table
          await txn.execute('DROP TABLE IF EXISTS $tablePlayers');

          await txn.execute('''
            CREATE TABLE $tablePlayers (
              id TEXT NOT NULL,
              gameId TEXT NOT NULL,
              name TEXT NOT NULL,
              buyIns INTEGER NOT NULL DEFAULT 1,
              loans REAL NOT NULL DEFAULT 0,
              cashOut REAL,
              isSettled INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (gameId) REFERENCES $tableGames (id) ON DELETE CASCADE,
              UNIQUE(id, gameId)
            )
          ''');

          // Restore data
          for (final player in players) {
            await txn.insert(tablePlayers, player);
          }

          // Create new index
          await txn.execute(
              'CREATE INDEX idx_players_composite ON $tablePlayers (id, gameId)');
        });
      }
    } catch (e) {
      print('Error in onUpgrade: $e'); // Debug log
      rethrow;
    }
  }

  // Method to delete database (useful for debugging)
  Future<void> deleteDatabase() async {
    try {
      final String path = join(await getDatabasesPath(), dbName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
    } catch (e) {
      print('Error deleting database: $e'); // Debug log
      rethrow;
    }
  }
}
