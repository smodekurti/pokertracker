import 'dart:async';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/poker_transaction.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../../../core/database/database_helper.dart';

class GameRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final String userId;
  final _activeGamesController = StreamController<List<Game>>.broadcast();
  final _gameHistoryController = StreamController<List<Game>>.broadcast();
  Timer? _refreshTimer;

  GameRepository({required this.userId}) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshStreams();
    });
  }

  // Add missing getAllGames method
  Future<List<Game>> getAllGames() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableGames,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return Future.wait(
      rows.map((row) => _createGameFromRow(db, row)),
    );
  }

  Stream<List<Game>> getActiveGames() {
    _refreshActiveGames();
    return _activeGamesController.stream;
  }

  Stream<List<Game>> getGameHistory() {
    _refreshGameHistory();
    return _gameHistoryController.stream;
  }

  // Fix type safety in createGameFromRow
  // In GameRepository class, modify the _createGameFromRow method:
  Future<Game> _createGameFromRow(Database db, Map<String, dynamic> row) async {
    final playerRows = await db.query(
      DatabaseHelper.tablePlayers,
      where: 'gameId = ?',
      whereArgs: [row['id'] as String],
    );

    final players = playerRows
        .map((p) => Player(
              id: p['id'] as String,
              name: p['name'] as String,
              buyIns: p['buyIns'] as int,
              loans: (p['loans'] as num).toDouble(),
              cashOut: p['cashOut'] != null
                  ? (p['cashOut'] as num).toDouble()
                  : null,
              isSettled: (p['isSettled'] as int) == 1, // Convert int to bool
            ))
        .toList();

    final transactionRows = await db.query(
      DatabaseHelper.tableTransactions,
      where: 'gameId = ?',
      whereArgs: [row['id'] as String],
    );

    final transactions = transactionRows
        .map((t) => PokerTransaction(
              id: t['id'] as String,
              playerId: t['playerId'] as String,
              type: TransactionType.values.firstWhere(
                (e) => e.toString() == t['type'],
              ),
              amount: (t['amount'] as num).toDouble(),
              timestamp: DateTime.parse(t['timestamp'] as String),
              note: t['note'] as String?,
              relatedPlayerId: t['relatedPlayerId'] as String?,
              isReverted: (t['isReverted'] as int) == 1, // Convert int to bool
              revertedBy: t['revertedBy'] as String?,
              revertedAt: t['revertedAt'] != null
                  ? DateTime.parse(t['revertedAt'] as String)
                  : null,
            ))
        .toList();

    return Game(
      id: row['id'] as String,
      name: row['name'] as String,
      date: DateTime.parse(row['date'] as String),
      players: players,
      transactions: transactions,
      isActive: (row['isActive'] as int) == 1, // Convert int to bool
      createdBy: row['createdBy'] as String,
      buyInAmount: (row['buyInAmount'] as num).toDouble(),
      cutPercentage: (row['cutPercentage'] as num).toDouble(),
      createdAt: DateTime.parse(row['createdAt'] as String),
      endedAt: row['endedAt'] != null
          ? DateTime.parse(row['endedAt'] as String)
          : null,
    );
  }

  // ... rest of the existing methods ...

  Future<String> createGame(Game game) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // First, insert the game
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

      // For each player, try to insert or update
      for (final player in game.players) {
        try {
          await txn.insert(DatabaseHelper.tablePlayers, {
            'id': player.id,
            'gameId': game.id,
            'name': player.name,
            'buyIns': player.buyIns,
            'loans': player.loans,
            'cashOut': player.cashOut,
            'isSettled': player.isSettled ? 1 : 0,
          });
        } on DatabaseException catch (e) {
          if (e.isUniqueConstraintError()) {
            // If player already exists, update instead
            await txn.update(
              DatabaseHelper.tablePlayers,
              {
                'gameId': game.id,
                'name': player.name,
                'buyIns': player.buyIns,
                'loans': player.loans,
                'cashOut': player.cashOut,
                'isSettled': player.isSettled ? 1 : 0,
              },
              where: 'id = ?',
              whereArgs: [player.id],
            );
          } else {
            rethrow;
          }
        }
      }
    });

    _refreshStreams();
    return game.id;
  }

// Also modify the addPlayer method:
  Future<void> addPlayer(String gameId, Player player) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      try {
        await txn.insert(DatabaseHelper.tablePlayers, {
          'id': player.id,
          'gameId': gameId,
          'name': player.name,
          'buyIns': player.buyIns,
          'loans': player.loans,
          'cashOut': player.cashOut,
          'isSettled': player.isSettled ? 1 : 0,
        });
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          await txn.update(
            DatabaseHelper.tablePlayers,
            {
              'gameId': gameId,
              'name': player.name,
              'buyIns': player.buyIns,
              'loans': player.loans,
              'cashOut': player.cashOut,
              'isSettled': player.isSettled ? 1 : 0,
            },
            where: 'id = ?',
            whereArgs: [player.id],
          );
        } else {
          rethrow;
        }
      }
    });

    _refreshStreams();
  }

  Stream<Game?> getGame(String gameId) {
    final controller = StreamController<Game?>();

    void queryGame() async {
      try {
        final db = await _db.database;
        final rows = await db.query(
          DatabaseHelper.tableGames,
          where: 'id = ? AND userId = ?',
          whereArgs: [gameId, userId],
        );

        if (rows.isEmpty) {
          controller.add(null);
        } else {
          final game = await _createGameFromRow(db, rows.first);
          controller.add(game);
        }
      } catch (e) {
        controller.addError(e);
      }
    }

    // Initial query
    queryGame();

    // Setup periodic refresh
    final timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => queryGame(),
    );

    // Clean up
    controller.onCancel = () {
      timer.cancel();
    };

    return controller.stream;
  }

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
    await _refreshActiveGames();
    await _refreshGameHistory();
  }

  Future<void> _refreshActiveGames() async {
    try {
      final db = await _db.database;
      final games = await _queryGames(db, isActive: true);
      _activeGamesController.add(games);
    } catch (e) {
      _activeGamesController.addError(e);
    }
  }

  Future<void> _refreshGameHistory() async {
    try {
      final db = await _db.database;
      final games = await _queryGames(db, isActive: false);
      _gameHistoryController.add(games);
    } catch (e) {
      _gameHistoryController.addError(e);
    }
  }

  Future<List<Game>> _queryGames(Database db, {required bool isActive}) async {
    final rows = await db.query(
      DatabaseHelper.tableGames,
      where: 'isActive = ? AND userId = ?',
      whereArgs: [isActive ? 1 : 0, userId],
      orderBy: isActive ? 'createdAt DESC' : 'endedAt DESC',
    );

    return Future.wait(rows.map((row) => _createGameFromRow(db, row)));
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

  void dispose() {
    _refreshTimer?.cancel();
    _activeGamesController.close();
    _gameHistoryController.close();
  }
}

extension DatabaseExceptionExt on DatabaseException {
  bool isUniqueConstraintError() {
    return this.toString().contains('UNIQUE constraint failed');
  }
}
