import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String dbName = 'poker_tracker.db';
  static const int dbVersion = 1;

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
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableGames (
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

    await db.execute('''
  CREATE TABLE $tablePlayers (
    id TEXT PRIMARY KEY,
    gameId TEXT NOT NULL,
    name TEXT NOT NULL,
    buyIns INTEGER NOT NULL DEFAULT 1,
    loans REAL NOT NULL DEFAULT 0,
    cashOut REAL,
    isSettled INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (gameId) REFERENCES $tableGames (id) ON DELETE CASCADE,
    UNIQUE(id)
  )
''');

    await db.execute('''
      CREATE TABLE $tableTransactions (
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
        FOREIGN KEY (playerId) REFERENCES $tablePlayers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTeams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdBy TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        userId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTeamPlayers (
        id TEXT PRIMARY KEY,
        teamId TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (teamId) REFERENCES $tableTeams (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_games_userId ON $tableGames (userId)');
    await db
        .execute('CREATE INDEX idx_games_isActive ON $tableGames (isActive)');
    await db
        .execute('CREATE INDEX idx_players_gameId ON $tablePlayers (gameId)');
    await db.execute(
        'CREATE INDEX idx_transactions_gameId ON $tableTransactions (gameId)');
    await db.execute('CREATE INDEX idx_teams_userId ON $tableTeams (userId)');
  }
}
