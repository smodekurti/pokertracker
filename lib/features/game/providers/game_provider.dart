import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/poker_transaction.dart';
import 'package:poker_tracker/features/game/data/repositories/game_repository.dart';
import 'package:uuid/uuid.dart';

class GameProvider with ChangeNotifier {
  final GameRepository _repository;
  Game? _currentGame;
  late String _userId;
  List<Game> _activeGames = [];
  List<Game> _gameHistory = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _currentGameSubscription;
  StreamSubscription? _activeGamesSubscription;
  StreamSubscription? _gameHistorySubscription;

  GameProvider(String userId) : _repository = GameRepository(userId: userId) {
    if (userId.isNotEmpty) {
      this._userId = userId;
      _initializeStreams();
    }
  }

  // Getters
  Game? get currentGame => _currentGame;
  List<Game> get activeGames => _activeGames;
  List<Game> get gameHistory => _gameHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveGame => _currentGame != null;
  bool get hasUnsettledPlayers =>
      _currentGame?.players.any((p) => !p.isSettled) ?? false;
  double get totalPot => _currentGame?.totalPot ?? 0.0;

  // Stream Management
  void _initializeStreams() {
    _listenToActiveGames();
    _listenToGameHistory();
  }

  void _listenToActiveGames() {
    _activeGamesSubscription?.cancel();
    _activeGamesSubscription = _repository.getActiveGames().listen(
      (games) {
        _activeGames = games;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  void _listenToGameHistory() {
    _gameHistorySubscription?.cancel();
    _gameHistorySubscription = _repository.getGameHistory().listen(
      (games) {
        _gameHistory = games;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  Future<List<Game>> getAllGames() async {
    return await _repository.getAllGames();
  }

  Future<void> refreshGames() async {
    try {
      _setLoading(true);
      _clearError();
      await _activeGamesSubscription?.cancel();
      await _gameHistorySubscription?.cancel();
      _initializeStreams();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Game Management
// Update the createGame method in GameProvider
  Future<void> createGame(
    String name,
    double buyInAmount,
    List<Player> players,
    double cutPercentage,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final game = Game(
        id: const Uuid().v4(),
        name: name,
        date: DateTime.now(),
        players: players,
        createdBy: _repository.userId,
        buyInAmount: buyInAmount,
        cutPercentage: cutPercentage,
        createdAt: DateTime.now(),
      );

      final gameId = await _repository.createGame(game);
      _currentGame = await _repository.getGame(gameId).first;
      notifyListeners();

      _currentGameSubscription?.cancel();
      _currentGameSubscription = _repository.getGame(gameId).listen(
        (game) {
          _currentGame = game;
          notifyListeners();
        },
        onError: (error) {
          _setError(error.toString());
        },
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Game? _findGameInCache(String gameId) {
    final activeGame = _activeGames.cast<Game?>().firstWhere(
          (game) => game?.id == gameId,
          orElse: () => null,
        );
    if (activeGame != null) return activeGame;

    return _gameHistory.cast<Game?>().firstWhere(
          (game) => game?.id == gameId,
          orElse: () => null,
        );
  }

  Future<void> loadGame(String gameId) async {
    try {
      _setLoading(true);
      _clearError();

      _currentGameSubscription?.cancel();

      final cachedGame = _findGameInCache(gameId);
      if (cachedGame != null) {
        _currentGame = cachedGame;
        notifyListeners();
      }
      // Wrap the stream subscription in a delayed future
      await Future.delayed(const Duration(milliseconds: 100));

      _currentGameSubscription = _repository.getGame(gameId).listen(
        (game) {
          if (game == null) {
            if (_currentGame == null) {
              _setError('Game not found');
            }
            return;
          }
          _currentGame = game;
          notifyListeners();
        },
        onError: (error) {
          _setError(error.toString());
        },
      );
    } catch (e) {
      _setError('Failed to load game: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Player Management
  Future<void> addPlayer(Player player) async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }
      _setLoading(true);
      await _repository.addPlayer(_currentGame!.id, player);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Transaction Management
  Future<void> addTransaction(PokerTransaction transaction) async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }

      if (!_currentGame!.players.any((p) => p.id == transaction.playerId)) {
        throw Exception('Player not found in this game');
      }

      _setLoading(true);
      await _repository.addTransaction(_currentGame!.id, transaction);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> handleReEntry(String playerId) async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }
      _setLoading(true);

      final transaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: playerId,
        type: TransactionType.reEntry,
        amount: _currentGame!.buyInAmount,
        timestamp: DateTime.now(),
        note: 'Re-entry',
      );

      await addTransaction(transaction);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Loan Management
  Future<void> handleLoan({
    required String lenderId,
    required String recipientId,
    required double amount,
  }) async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }

      final lender = _currentGame!.players.firstWhere(
        (p) => p.id == lenderId,
        orElse: () => throw Exception('Lender not found in this game'),
      );

      final recipient = _currentGame!.players.firstWhere(
        (p) => p.id == recipientId,
        orElse: () => throw Exception('Recipient not found in this game'),
      );

      // Update player states with the loan
      final updatedPlayers = _currentGame!.players.map((player) {
        if (player.id == lenderId) {
          // Reduce lender's amount by the loan amount
          return player.copyWith(
            buyIns: player.buyIns,
            loans:
                player.loans - amount, // Reduce lender's money by loan amount
          );
        } else if (player.id == recipientId) {
          // Add loan amount to recipient
          return player.copyWith(
            buyIns: player.buyIns,
            loans: player.loans +
                amount, // Increase recipient's money by loan amount
          );
        }
        return player;
      }).toList();

      // Create transactions to track the loan
      final lenderTransaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: lenderId,
        type: TransactionType.loan,
        amount: -amount, // Negative as they're giving money
        timestamp: DateTime.now(),
        note: 'Loan to ${recipient.name}',
        relatedPlayerId: recipientId,
      );

      final recipientTransaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: recipientId,
        type: TransactionType.loan,
        amount: amount, // Positive as they're receiving money
        timestamp: DateTime.now(),
        note: 'Loan from ${lender.name}',
        relatedPlayerId: lenderId,
      );

      // Update game state with new players
      _currentGame = _currentGame!.copyWith(
        players: updatedPlayers,
      );

      // Execute transactions
      await addTransaction(lenderTransaction);
      await addTransaction(recipientTransaction);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Settlement Management
  Future<void> settlePlayer(String playerId, double amount) async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }

      _setLoading(true);

      final transaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: playerId,
        type: TransactionType.settlement,
        amount: amount,
        timestamp: DateTime.now(),
        note: 'Final settlement',
      );

      await addTransaction(transaction);

      // Update the current game's player with new settlement
      final updatedPlayers = _currentGame!.players.map((player) {
        if (player.id == playerId) {
          return player.copyWith(cashOut: amount, isSettled: true);
        }
        return player;
      }).toList();

      _currentGame = _currentGame!.copyWith(players: updatedPlayers);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Game> settleAllAndEnd() async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }

      _setLoading(true);

      if (!_currentGame!.players.every((p) => p.isSettled)) {
        throw Exception('All players must be settled before ending the game');
      }

      await _repository.endGame(_currentGame!.id);

      final endedGame = _currentGame!.copyWith(
        isActive: false,
        endedAt: DateTime.now(),
      );

      _activeGames.removeWhere((game) => game.id == endedGame.id);
      _gameHistory.insert(0, endedGame);

      // Store the ended game before clearing current game
      final finalGameState = endedGame;

      _currentGame = null;
      _currentGameSubscription?.cancel();

      notifyListeners();
      return finalGameState; // Return the final game state
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Game End Management
  Future<void> endGame() async {
    try {
      if (_currentGame == null) {
        throw Exception('No active game');
      }

      if (!_currentGame!.players.every((p) => p.isSettled)) {
        throw Exception('All players must be settled before ending the game');
      }

      _setLoading(true);
      await _repository.endGame(_currentGame!.id);

      final endedGame = _currentGame!.copyWith(
        isActive: false,
        endedAt: DateTime.now(),
      );

      _activeGames.removeWhere((game) => game.id == endedGame.id);
      _gameHistory.insert(0, endedGame);
      _currentGame = null;
      _currentGameSubscription?.cancel();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Settlement Calculations
  List<Map<String, dynamic>> calculateSettlements() {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    final settlements = <Map<String, dynamic>>[];
    final balances = <String, double>{};

    // Calculate net balance for each player
    for (final player in _currentGame!.players) {
      if (!player.isSettled) {
        throw Exception(
            'All players must be settled before calculating settlements');
      }
      final totalIn = player.calculateTotalIn(_currentGame!.buyInAmount);
      final cashOut = player.cashOut ?? 0;
      balances[player.id] = cashOut - totalIn;
    }

    while (balances.values.any((b) => b.abs() > 0.01)) {
      final sortedBalances = balances.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final debtor = sortedBalances.first;
      final creditor = sortedBalances.last;

      final amount = math.min(debtor.value.abs(), creditor.value.abs());

      if (amount > 0.01) {
        final fromPlayer =
            _currentGame!.players.firstWhere((p) => p.id == debtor.key);
        final toPlayer =
            _currentGame!.players.firstWhere((p) => p.id == creditor.key);

        settlements.add({
          'from': fromPlayer.name,
          'to': toPlayer.name,
          'amount': amount,
        });

        balances[debtor.key] = debtor.value + amount;
        balances[creditor.key] = creditor.value - amount;
      }
    }

    return settlements;
  }

  // Game Deletion
  Future<void> deleteGame(String gameId) async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.deleteGame(gameId);

      _activeGames = _activeGames.where((game) => game.id != gameId).toList();
      _gameHistory = _gameHistory.where((game) => game.id != gameId).toList();

      if (_currentGame?.id == gameId) {
        _currentGame = null;
        _currentGameSubscription?.cancel();
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper Methods
  bool canSettlePlayer(String playerId) {
    if (_currentGame == null) return false;
    final player = _currentGame!.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw Exception('Player not found'),
    );
    return !player.isSettled;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentGameSubscription?.cancel();
    _activeGamesSubscription?.cancel();
    _gameHistorySubscription?.cancel();
    super.dispose();
  }
}
