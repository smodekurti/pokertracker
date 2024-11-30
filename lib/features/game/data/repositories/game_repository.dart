import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/poker_transaction.dart';

class GameRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  GameRepository({required this.userId}) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    print('Initializing GameRepository with userId: $userId'); // Debug log
  }

  // Collection reference
  CollectionReference get _gamesCollection {
    return _db
        .collection('users') // Make sure this matches your Firebase structure
        .doc(userId)
        .collection('games');
  }

  // Get active games
  Stream<List<Game>> getActiveGames() {
    try {
      return _gamesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return Game.fromFirestore(doc);
          } catch (e) {
            print('Error parsing game document: $e');
            rethrow;
          }
        }).toList();
      });
    } catch (e) {
      print('Error getting active games: $e');
      throw _handleFirestoreException(e);
    }
  }

  // Get game history
  Stream<List<Game>> getGameHistory() {
    try {
      return _gamesCollection
          .where('isActive', isEqualTo: false)
          .orderBy('endedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return Game.fromFirestore(doc);
          } catch (e) {
            print('Error parsing game document: $e');
            rethrow;
          }
        }).toList();
      });
    } catch (e) {
      print('Error getting game history: $e');
      throw _handleFirestoreException(e);
    }
  }

  // Create new game
  Future<String> createGame(Game game) async {
    try {
      final gameRef = _gamesCollection.doc();

      final gameData = {
        'id': gameRef.id,
        'name': game.name,
        'date': game.date.toIso8601String(),
        'players': game.players.map((p) => p.toMap()).toList(),
        'transactions': [],
        'isActive': true,
        'createdBy': userId,
        'buyInAmount': game.buyInAmount,
        'cutPercentage': game.cutPercentage,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await gameRef.set(gameData);
      return gameRef.id;
    } catch (e) {
      print('Error creating game: $e');
      throw _handleFirestoreException(e);
    }
  }

// In GameRepository class
  Future<void> deleteGame(String gameId) async {
    try {
      print('Attempting to delete game: $gameId'); // Debug log

      // Get reference to the game document
      final gameRef = _gamesCollection.doc(gameId);

      // Delete the game document
      await gameRef.delete();

      print('Game deleted successfully from Firebase'); // Debug log
    } catch (e) {
      print('Error deleting game: $e');
      throw _handleFirestoreException(e);
    }
  }

// Get single game
  Stream<Game?> getGame(String gameId) {
    try {
      return _gamesCollection.doc(gameId).snapshots().map((doc) {
        if (!doc.exists) return null;
        try {
          return Game.fromFirestore(doc);
        } catch (e) {
          print('Error parsing game data: $e');
          rethrow;
        }
      });
    } catch (e) {
      print('Error getting game: $e');
      throw _handleFirestoreException(e);
    }
  }

  // Add transaction
  Future<void> addTransaction(
      String gameId, PokerTransaction transaction) async {
    try {
      return _db.runTransaction((txn) async {
        final gameDoc = await txn.get(_gamesCollection.doc(gameId));

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final data = gameDoc.data() as Map<String, dynamic>;
        final currentTransactions = List<Map<String, dynamic>>.from(
            data['transactions'] as List<dynamic>? ?? []);

        final currentGame = Game.fromFirestore(gameDoc);

        if (!currentGame.players.any((p) => p.id == transaction.playerId)) {
          throw Exception('Player not found in this game');
        }

        currentTransactions.add(transaction.toMap());

        final updatedPlayers = currentGame.players.map((player) {
          if (player.id == transaction.playerId) {
            switch (transaction.type) {
              case TransactionType.buyIn:
              case TransactionType.reEntry:
                return player.copyWith(buyIns: player.buyIns + 1);
              case TransactionType.loan:
                return player.copyWith(
                    loans: player.loans + transaction.amount);
              case TransactionType.settlement:
                return player.copyWith(
                  isSettled: true,
                  cashOut: transaction.amount,
                );
            }
          }
          return player;
        }).toList();

        txn.update(gameDoc.reference, {
          'transactions': currentTransactions,
          'players': updatedPlayers.map((p) => p.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error adding transaction: $e');
      throw _handleFirestoreException(e);
    }
  }

  Future<List<Game>> getAllGames() async {
    final QuerySnapshot snapshot = await _db
        .collection('users') // Make sure this matches your Firebase structure
        .doc(userId)
        .collection('games')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Game.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList();
  }

  // Add player
  Future<void> addPlayer(String gameId, Player player) async {
    try {
      return _db.runTransaction((txn) async {
        final gameDoc = await txn.get(_gamesCollection.doc(gameId));

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final data = gameDoc.data() as Map<String, dynamic>;
        final currentPlayers = List<Map<String, dynamic>>.from(
            data['players'] as List<dynamic>? ?? []);

        if (currentPlayers.any((p) => p['id'] == player.id)) {
          throw Exception('Player already exists in this game');
        }

        currentPlayers.add(player.toMap());

        txn.update(gameDoc.reference, {
          'players': currentPlayers,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error adding player: $e');
      throw _handleFirestoreException(e);
    }
  }

  // End game
// In GameRepository class
  Future<void> endGame(String gameId) async {
    try {
      await _gamesCollection.doc(gameId).update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Optional: Log for debugging
      print('Game $gameId ended successfully');
    } catch (e) {
      print('Error ending game: $e');
      throw _handleFirestoreException(e);
    }
  }

  Exception _handleFirestoreException(dynamic e) {
    if (e is FirebaseException) {
      print('Firebase Error Code: ${e.code}');
      print('Firebase Error Message: ${e.message}');

      switch (e.code) {
        case 'permission-denied':
          return Exception(
              'You don\'t have permission to access this resource');
        case 'not-found':
          return Exception('The requested resource was not found');
        case 'already-exists':
          return Exception('The resource already exists');
        default:
          return Exception(e.message ?? 'An unknown error occurred');
      }
    }
    return Exception('Failed to perform operation: ${e.toString()}');
  }
}
