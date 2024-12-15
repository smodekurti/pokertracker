import 'dart:async';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/poker_transaction.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';

class GameRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final String userId;
  final _activeGamesController = StreamController<List<Game>>.broadcast();
  final _gameHistoryController = StreamController<List<Game>>.broadcast();
  bool _isDisposed = false;

  Timer? _refreshTimer;

  GameRepository({required this.userId}) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed) {
        _refreshStreams();
      }
    });
  }

  // Get all games with optimized query
  Future<List<Game>> getAllGames() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT 
        g.*,
        GROUP_CONCAT(p.id || ',' || 
                    p.name || ',' || 
                    p.buyIns || ',' || 
                    p.loans || ',' || 
                    COALESCE(p.cashOut, '') || ',' || 
                    p.isSettled) as player_data,
        GROUP_CONCAT(t.id || ',' || 
                    t.playerId || ',' || 
                    t.type || ',' || 
                    t.amount || ',' || 
                    t.timestamp || ',' || 
                    COALESCE(t.note, '') || ',' || 
                    COALESCE(t.relatedPlayerId, '') || ',' || 
                    t.isReverted || ',' || 
                    COALESCE(t.revertedBy, '') || ',' || 
                    COALESCE(t.revertedAt, '')) as transaction_data
      FROM ${DatabaseHelper.tableGames} g
      LEFT JOIN ${DatabaseHelper.tablePlayers} p ON g.id = p.gameId
      LEFT JOIN ${DatabaseHelper.tableTransactions} t ON g.id = t.gameId
      WHERE g.userId = ?
      GROUP BY g.id
      ORDER BY g.createdAt DESC
    ''', [userId]);

    return rows.map((row) => _createGameFromRowOptimized(row)).toList();
  }

  Stream<List<Game>> getActiveGames() {
    if (!_isDisposed) {
      _refreshActiveGames();
    }
    return _activeGamesController.stream;
  }

  Stream<List<Game>> getGameHistory() {
    if (!_isDisposed) {
      _refreshGameHistory();
    }
    return _gameHistoryController.stream;
  }

  // Optimized game creation from row
  Game _createGameFromRowOptimized(Map<String, dynamic> row) {
    final players = _parsePlayersFromConcat(row['player_data'] as String?);
    final transactions =
        _parseTransactionsFromConcat(row['transaction_data'] as String?);

    return Game(
      id: row['id'] as String,
      name: row['name'] as String,
      date: DateTime.parse(row['date'] as String),
      players: players,
      transactions: transactions,
      isActive: (row['isActive'] as int) == 1,
      createdBy: row['createdBy'] as String,
      buyInAmount: (row['buyInAmount'] as num).toDouble(),
      cutPercentage: (row['cutPercentage'] as num).toDouble(),
      createdAt: DateTime.parse(row['createdAt'] as String),
      endedAt: row['endedAt'] != null
          ? DateTime.parse(row['endedAt'] as String)
          : null,
    );
  }

  List<Player> _parsePlayersFromConcat(String? playerData) {
    if (playerData == null || playerData.isEmpty) return [];

    try {
      // Split into individual player records first
      final playerRecords = playerData.split(') ('); // Split player records

      return playerRecords.map((record) {
        // Clean up the record string
        record = record.replaceAll('(', '').replaceAll(')', '');
        final parts = record.split(',');

        // Add debug logging

        if (parts.length < 6) {
          // Return a default player if data is incomplete
          return Player(
            id: parts.isNotEmpty ? parts[0] : const Uuid().v4(),
            name: parts.length > 1 ? parts[1] : 'Unknown',
            buyIns: parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1,
            loans: parts.length > 3 ? double.tryParse(parts[3]) ?? 0.0 : 0.0,
            cashOut: parts.length > 4 && parts[4].isNotEmpty
                ? double.tryParse(parts[4])
                : null,
            isSettled: parts.length > 5 ? parts[5] == '1' : false,
          );
        }

        return Player(
          id: parts[0],
          name: parts[1],
          buyIns: int.parse(parts[2]),
          loans: double.parse(parts[3]),
          cashOut: parts[4].isNotEmpty ? double.parse(parts[4]) : null,
          isSettled: parts[5] == '1',
        );
      }).toList();
    } catch (e) {
      return []; // Return empty list on error instead of crashing
    }
  }

  List<PokerTransaction> _parseTransactionsFromConcat(String? transactionData) {
    if (transactionData == null || transactionData.isEmpty) return [];

    return transactionData.split(',').map((transStr) {
      final parts = transStr.split(',');
      return PokerTransaction(
        id: parts[0],
        playerId: parts[1],
        type:
            TransactionType.values.firstWhere((e) => e.toString() == parts[2]),
        amount: double.parse(parts[3]),
        timestamp: DateTime.parse(parts[4]),
        note: parts[5].isNotEmpty ? parts[5] : null,
        relatedPlayerId: parts[6].isNotEmpty ? parts[6] : null,
        isReverted: parts[7] == '1',
        revertedBy: parts[8].isNotEmpty ? parts[8] : null,
        revertedAt: parts[9].isNotEmpty ? DateTime.parse(parts[9]) : null,
      );
    }).toList();
  }

  Future<String> createGame(Game game) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // Insert game
      await txn.insert(DatabaseHelper.tableGames, {
        'id': game.id,
        'name': game.name,
        'date': game.date.toIso8601String(),
        'isActive': 1,
        'createdBy': userId,
        'buyInAmount': game.buyInAmount,
        'cutPercentage': game.cutPercentage,
        'createdAt': game.createdAt.toIso8601String(),
        'userId': userId,
      });

      // Insert players with game-specific data
      for (final player in game.players) {
        await txn.insert(DatabaseHelper.tablePlayers, {
          'id': player.id,
          'gameId': game.id,
          'name': player.name,
          'buyIns': player.buyIns,
          'loans': player.loans,
          'cashOut': player.cashOut,
          'isSettled': player.isSettled ? 1 : 0,
        });
      }
    });

    _refreshStreams();
    return game.id; // Return the game ID
  }

  Future<void> updatePlayer(String gameId, Player player) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // First check if the player exists
      final playerExists = await txn.query(
        DatabaseHelper.tablePlayers,
        where: 'id = ? AND gameId = ?',
        whereArgs: [player.id, gameId],
      );

      if (playerExists.isEmpty) {
        throw Exception('Player not found in this game');
      }

      // Update the player record
      await txn.update(
        DatabaseHelper.tablePlayers,
        {
          'name': player.name,
          'buyIns': player.buyIns,
          'loans': player.loans,
          'cashOut': player.cashOut,
          'isSettled': player.isSettled ? 1 : 0,
        },
        where: 'id = ? AND gameId = ?',
        whereArgs: [player.id, gameId],
      );

      // If this is a reentry (buyIns increased), create a transaction record
      final existingPlayer = Player(
        id: playerExists.first['id'] as String,
        name: playerExists.first['name'] as String,
        buyIns: playerExists.first['buyIns'] as int,
        loans: (playerExists.first['loans'] as num).toDouble(),
        cashOut: playerExists.first['cashOut'] != null
            ? (playerExists.first['cashOut'] as num).toDouble()
            : null,
        isSettled: (playerExists.first['isSettled'] as int) == 1,
      );

      if (player.buyIns > existingPlayer.buyIns) {
        // Get game details for buy-in amount
        final gameDetails = await txn.query(
          DatabaseHelper.tableGames,
          where: 'id = ?',
          whereArgs: [gameId],
        );

        if (gameDetails.isNotEmpty) {
          final buyInAmount =
              (gameDetails.first['buyInAmount'] as num).toDouble();

          // Create reentry transaction
          await txn.insert(
            DatabaseHelper.tableTransactions,
            {
              'id': const Uuid().v4(),
              'gameId': gameId,
              'playerId': player.id,
              'type': TransactionType.reEntry.toString(),
              'amount': buyInAmount,
              'timestamp': DateTime.now().toIso8601String(),
              'note': 'Reentry',
              'isReverted': 0,
            },
          );
        }
      }
    });

    _refreshStreams();
  }

  Future<void> addPlayer(String gameId, Player player) async {
    final db = await _db.database;

    await db.insert(DatabaseHelper.tablePlayers, {
      'id': player.id,
      'gameId': gameId,
      'name': player.name,
      'buyIns': player.buyIns,
      'loans': player.loans,
      'cashOut': player.cashOut,
      'isSettled': player.isSettled ? 1 : 0,
    });

    _refreshStreams();
  }

  Stream<Game?> getGame(String gameId) {
    final controller = StreamController<Game?>();

    void queryGame() async {
      try {
        final db = await _db.database;

        // Get the game
        final gameRows = await db.query(
          DatabaseHelper.tableGames,
          where: 'id = ? AND userId = ?',
          whereArgs: [gameId, userId],
        );

        if (gameRows.isEmpty) {
          controller.add(null);
          return;
        }

        final gameRow = gameRows.first;

        // Get players for this game
        final playerRows = await db.query(
          DatabaseHelper.tablePlayers,
          where: 'gameId = ?',
          whereArgs: [gameId],
        );

        // Get transactions for this game
        final transactionRows = await db.query(
          DatabaseHelper.tableTransactions,
          where: 'gameId = ?',
          whereArgs: [gameId],
        );

        final players = playerRows
            .map((row) => Player(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  buyIns: row['buyIns'] as int,
                  loans: (row['loans'] as num).toDouble(),
                  cashOut: row['cashOut'] != null
                      ? (row['cashOut'] as num).toDouble()
                      : null,
                  isSettled: (row['isSettled'] as int) == 1,
                ))
            .toList();

        final transactions = transactionRows
            .map((row) => PokerTransaction(
                  id: row['id'] as String,
                  playerId: row['playerId'] as String,
                  type: TransactionType.values.firstWhere(
                    (e) => e.toString() == row['type'] as String,
                  ),
                  amount: (row['amount'] as num).toDouble(),
                  timestamp: DateTime.parse(row['timestamp'] as String),
                  note: row['note'] as String?,
                  relatedPlayerId: row['relatedPlayerId'] as String?,
                  isReverted: (row['isReverted'] as int) == 1,
                  revertedBy: row['revertedBy'] as String?,
                  revertedAt: row['revertedAt'] != null
                      ? DateTime.parse(row['revertedAt'] as String)
                      : null,
                ))
            .toList();

        final game = Game(
          id: gameRow['id'] as String,
          name: gameRow['name'] as String,
          date: DateTime.parse(gameRow['date'] as String),
          players: players,
          transactions: transactions,
          isActive: (gameRow['isActive'] as int) == 1,
          createdBy: gameRow['createdBy'] as String,
          buyInAmount: (gameRow['buyInAmount'] as num).toDouble(),
          cutPercentage: (gameRow['cutPercentage'] as num).toDouble(),
          createdAt: DateTime.parse(gameRow['createdAt'] as String),
          endedAt: gameRow['endedAt'] != null
              ? DateTime.parse(gameRow['endedAt'] as String)
              : null,
        );

        controller.add(game);
      } catch (e) {
        print('Error in getGame: $e');
        controller.addError(e);
      }
    }

    queryGame();
    final timer =
        Timer.periodic(const Duration(seconds: 1), (_) => queryGame());

    controller.onCancel = () {
      timer.cancel();
    };

    return controller.stream;
  }

  // Analytics Methods
  Future<Map<String, dynamic>> getPlayerStats(String playerId) async {
    final db = await _db.database;
    final stats = await db.rawQuery('''
      WITH PlayerGames AS (
        SELECT 
          p.*,
          g.buyInAmount,
          g.cutPercentage,
          COALESCE(p.cashOut, 0) - (p.buyIns * g.buyInAmount + p.loans) as net_amount
        FROM ${DatabaseHelper.tablePlayers} p
        JOIN ${DatabaseHelper.tableGames} g ON p.gameId = g.id
        WHERE p.id = ?
      )
      SELECT 
        COUNT(*) as total_games,
        SUM(buyIns) as total_buyins,
        SUM(loans) as total_loans,
        SUM(CASE WHEN net_amount > 0 THEN 1 ELSE 0 END) as winning_games,
        AVG(net_amount) as avg_profit,
        MAX(net_amount) as biggest_win,
        MIN(net_amount) as biggest_loss,
        SUM(net_amount) as total_profit
      FROM PlayerGames
    ''', [playerId]);

    return stats.first;
  }

  Future<List<Map<String, dynamic>>> getGameAnalytics() async {
    final db = await _db.database;
    return await db.rawQuery('''
      WITH GameStats AS (
        SELECT 
          g.id,
          g.date,
          COUNT(DISTINCT p.id) as player_count,
          SUM(p.buyIns * g.buyInAmount + p.loans) as total_pot,
          g.buyInAmount,
          g.cutPercentage
        FROM ${DatabaseHelper.tableGames} g
        JOIN ${DatabaseHelper.tablePlayers} p ON g.id = p.gameId
        WHERE g.userId = ?
        GROUP BY g.id
      )
      SELECT 
        strftime('%Y-%m', date) as month,
        COUNT(*) as games_count,
        AVG(player_count) as avg_players,
        AVG(total_pot) as avg_pot,
        MAX(total_pot) as max_pot,
        AVG(buyInAmount) as avg_buyin,
        SUM(total_pot) as total_volume
      FROM GameStats
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month DESC
    ''', [userId]);
  }

  // Keep existing methods unchanged...
  Future<void> addTransaction(
      String gameId, PokerTransaction transaction) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(DatabaseHelper.tableTransactions, {
        'id': transaction.id,
        'gameId': gameId,
        'playerId': transaction.playerId,
        'type': transaction.type.toString(),
        'amount': transaction.amount,
        'timestamp': transaction.timestamp.toIso8601String(),
        'note': transaction.note,
        'relatedPlayerId': transaction.relatedPlayerId,
        'isReverted': transaction.isReverted ? 1 : 0,
        'revertedBy': transaction.revertedBy,
        'revertedAt': transaction.revertedAt?.toIso8601String(),
      });

      await _updatePlayerForTransaction(txn, gameId, transaction);
    });

    _refreshStreams();
  }

  Future<void> _updatePlayerForTransaction(
      Transaction txn, String gameId, PokerTransaction transaction) async {
    switch (transaction.type) {
      case TransactionType.buyIn:
      case TransactionType.reEntry:
        await txn.rawUpdate('''
          UPDATE ${DatabaseHelper.tablePlayers}
          SET buyIns = buyIns + 1
          WHERE id = ? AND gameId = ?
        ''', [transaction.playerId, gameId]);
        break;
      case TransactionType.loan:
        await txn.rawUpdate('''
          UPDATE ${DatabaseHelper.tablePlayers}
          SET loans = loans + ?
          WHERE id = ? AND gameId = ?
        ''', [transaction.amount, transaction.playerId, gameId]);
        break;
      case TransactionType.settlement:
        await txn.rawUpdate('''
          UPDATE ${DatabaseHelper.tablePlayers}
          SET cashOut = ?, isSettled = 1
          WHERE id = ? AND gameId = ?
        ''', [transaction.amount, transaction.playerId, gameId]);
        break;
    }
  }

  Future<void> endGame(String gameId) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableGames,
      {
        'isActive': 0,
        'endedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [gameId, userId],
    );
    _refreshStreams();
  }

  Future<void> deleteGame(String gameId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableGames,
      where: 'id = ? AND userId = ?',
      whereArgs: [gameId, userId],
    );
    _refreshStreams();
  }

  Future<void> _refreshStreams() async {
    if (!_isDisposed) {
      await _refreshActiveGames();
      await _refreshGameHistory();
    }
  }

  Future<void> _refreshActiveGames() async {
    if (_isDisposed || _activeGamesController.isClosed) return;

    try {
      final db = await _db.database;
      final games = await _queryGames(db, isActive: true);
      if (!_isDisposed && !_activeGamesController.isClosed) {
        _activeGamesController.add(games);
      }
    } catch (e) {
      if (!_isDisposed && !_activeGamesController.isClosed) {
        _activeGamesController.addError(e);
      }
    }
  }

  Future<void> _refreshGameHistory() async {
    if (_isDisposed || _gameHistoryController.isClosed) return;

    try {
      final db = await _db.database;
      final games = await _queryGames(db, isActive: false);
      if (!_isDisposed && !_gameHistoryController.isClosed) {
        _gameHistoryController.add(games);
      }
    } catch (e) {
      if (!_isDisposed && !_gameHistoryController.isClosed) {
        _gameHistoryController.addError(e);
      }
    }
  }

  Future<List<Game>> _queryGames(Database db, {required bool isActive}) async {
    try {
      // First, get all games
      final gameRows = await db.query(
        DatabaseHelper.tableGames,
        where: 'isActive = ? AND userId = ?',
        whereArgs: [isActive ? 1 : 0, userId],
        orderBy: isActive ? 'createdAt DESC' : 'endedAt DESC',
      );

      // Then get players for each game
      return Future.wait(gameRows.map((gameRow) async {
        // Get players for this game
        final playerRows = await db.query(
          DatabaseHelper.tablePlayers,
          where: 'gameId = ?',
          whereArgs: [gameRow['id']],
        );

        // Get transactions for this game
        final transactionRows = await db.query(
          DatabaseHelper.tableTransactions,
          where: 'gameId = ?',
          whereArgs: [gameRow['id']],
        );

        // Convert players and transactions
        final players = playerRows
            .map((row) => Player(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  buyIns: row['buyIns'] as int,
                  loans: (row['loans'] as num).toDouble(),
                  cashOut: row['cashOut'] != null
                      ? (row['cashOut'] as num).toDouble()
                      : null,
                  isSettled: (row['isSettled'] as int) == 1,
                ))
            .toList();

        final transactions = transactionRows
            .map((row) => PokerTransaction(
                  id: row['id'] as String,
                  playerId: row['playerId'] as String,
                  type: TransactionType.values.firstWhere(
                    (e) => e.toString() == row['type'] as String,
                  ),
                  amount: (row['amount'] as num).toDouble(),
                  timestamp: DateTime.parse(row['timestamp'] as String),
                  note: row['note'] as String?,
                  relatedPlayerId: row['relatedPlayerId'] as String?,
                  isReverted: (row['isReverted'] as int) == 1,
                  revertedBy: row['revertedBy'] as String?,
                  revertedAt: row['revertedAt'] != null
                      ? DateTime.parse(row['revertedAt'] as String)
                      : null,
                ))
            .toList();

        // Create game with all its players and transactions
        return Game(
          id: gameRow['id'] as String,
          name: gameRow['name'] as String,
          date: DateTime.parse(gameRow['date'] as String),
          players: players,
          transactions: transactions,
          isActive: (gameRow['isActive'] as int) == 1,
          createdBy: gameRow['createdBy'] as String,
          buyInAmount: (gameRow['buyInAmount'] as num).toDouble(),
          cutPercentage: (gameRow['cutPercentage'] as num).toDouble(),
          createdAt: DateTime.parse(gameRow['createdAt'] as String),
          endedAt: gameRow['endedAt'] != null
              ? DateTime.parse(gameRow['endedAt'] as String)
              : null,
        );
      }));
    } catch (e) {
      print('Error in _queryGames: $e');
      rethrow;
    }
  }

  // Additional Analytics Methods

  Future<Map<String, dynamic>> getPlayerTrends(String playerId) async {
    final db = await _db.database;
    return db.rawQuery('''
      WITH PlayerResults AS (
        SELECT 
          g.id as game_id,
          g.date,
          p.buyIns,
          p.loans,
          p.cashOut,
          g.buyInAmount,
          g.cutPercentage,
          COALESCE(p.cashOut, 0) - (p.buyIns * g.buyInAmount + p.loans) as net_amount,
          ROW_NUMBER() OVER (ORDER BY g.date) as game_number
        FROM ${DatabaseHelper.tablePlayers} p
        JOIN ${DatabaseHelper.tableGames} g ON p.gameId = g.id
        WHERE p.id = ? AND p.isSettled = 1
      )
      SELECT 
        game_number,
        date,
        net_amount,
        SUM(net_amount) OVER (ORDER BY date) as running_total,
        AVG(net_amount) OVER (ORDER BY date ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) as moving_average
      FROM PlayerResults
      ORDER BY date
    ''', [playerId]).then((results) => results.isNotEmpty ? results.first : {});
  }

  Future<List<Map<String, dynamic>>> getHeadToHeadStats(
      String player1Id, String player2Id) async {
    final db = await _db.database;
    return db.rawQuery('''
      WITH CommonGames AS (
        SELECT 
          g.id,
          g.date,
          p1.id as p1_id,
          p1.cashOut as p1_cashout,
          p1.buyIns as p1_buyins,
          p1.loans as p1_loans,
          p2.id as p2_id,
          p2.cashOut as p2_cashout,
          p2.buyIns as p2_buyins,
          p2.loans as p2_loans,
          g.buyInAmount
        FROM ${DatabaseHelper.tableGames} g
        JOIN ${DatabaseHelper.tablePlayers} p1 ON g.id = p1.gameId AND p1.id = ?
        JOIN ${DatabaseHelper.tablePlayers} p2 ON g.id = p2.gameId AND p2.id = ?
        WHERE p1.isSettled = 1 AND p2.isSettled = 1
      )
      SELECT 
        COUNT(*) as games_played,
        SUM(CASE WHEN (p1_cashout - (p1_buyins * buyInAmount + p1_loans)) > 
                  (p2_cashout - (p2_buyins * buyInAmount + p2_loans))
            THEN 1 ELSE 0 END) as p1_wins,
        SUM(CASE WHEN (p2_cashout - (p2_buyins * buyInAmount + p2_loans)) > 
                  (p1_cashout - (p1_buyins * buyInAmount + p1_loans))
            THEN 1 ELSE 0 END) as p2_wins,
        AVG(p1_cashout - (p1_buyins * buyInAmount + p1_loans)) as p1_avg_profit,
        AVG(p2_cashout - (p2_buyins * buyInAmount + p2_loans)) as p2_avg_profit
      FROM CommonGames
    ''', [player1Id, player2Id]);
  }

  // Helper method for player performance over time
  Future<List<Map<String, dynamic>>> getPlayerPerformanceTimeline(
      String playerId) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        strftime('%Y-%m', g.date) as month,
        COUNT(*) as games_played,
        SUM(p.buyIns) as total_buyins,
        SUM(p.loans) as total_loans,
        SUM(COALESCE(p.cashOut, 0)) as total_cashout,
        SUM(COALESCE(p.cashOut, 0) - (p.buyIns * g.buyInAmount + p.loans)) as net_profit,
        AVG(COALESCE(p.cashOut, 0) - (p.buyIns * g.buyInAmount + p.loans)) as avg_profit_per_game
      FROM ${DatabaseHelper.tablePlayers} p
      JOIN ${DatabaseHelper.tableGames} g ON p.gameId = g.id
      WHERE p.id = ? AND p.isSettled = 1
      GROUP BY strftime('%Y-%m', g.date)
      ORDER BY month DESC
    ''', [playerId]);
  }

  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    // Add try-catch blocks to handle cases where controllers might already be closed
    try {
      _activeGamesController.close();
    } catch (e) {
      print('Error closing active games controller: $e');
    }
    try {
      _gameHistoryController.close();
    } catch (e) {
      print('Error closing game history controller: $e');
    }
  }
}

extension DatabaseExceptionExt on DatabaseException {
  bool isUniqueConstraintError() {
    return toString().contains('UNIQUE constraint failed');
  }
}
