import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/poker_transaction.dart';
import 'package:poker_tracker/features/game/data/repositories/game_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // Import the collection package
import 'package:poker_tracker/core/presentation/styles/app_text_styles.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';

class GameProvider with ChangeNotifier {
  final GameRepository _repository;
  Game? _currentGame;
  List<Game> _activeGames = [];
  List<Game> _gameHistory = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _currentGameSubscription;
  StreamSubscription? _activeGamesSubscription;
  StreamSubscription? _gameHistorySubscription;

  GameProvider(String userId) : _repository = GameRepository(userId: userId) {
    if (userId.isNotEmpty) {
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

  Future<void> createGame(String name, double buyInAmount, List<Player> players,
      double cutPercentage) async {
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

      final gameId = await _repository.createGame(game); // Now returns String
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

  Future<void> updatePlayer(Player player) async {
    try {
      if (_currentGame == null) throw Exception('No active game');
      _setLoading(true);
      _clearError();

      await _repository.updatePlayer(_currentGame!.id, player);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGame(String gameId) async {
    try {
      _setLoading(true);
      _clearError();

      _currentGameSubscription?.cancel();

      // Find the game in cached lists first
      final cachedGame = _findGameInCache(gameId);
      if (cachedGame != null) {
        _currentGame = cachedGame;
        notifyListeners();
      }

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

  Game? _findGameInCache(String gameId) {
    return _activeGames.cast<Game?>().firstWhere(
          (game) => game?.id == gameId,
          orElse: () => _gameHistory.cast<Game?>().firstWhere(
                (game) => game?.id == gameId,
                orElse: () => null,
              ),
        );
  }

  // Helper method to check if a player has any active related sessions
  bool hasActiveRelatedSessions(String playerId) {
    if (_currentGame == null) return false;

    // Get all related players (either this player or players sharing same original ID)
    final relatedPlayers = _currentGame!.players.where((p) {
      // If this is the player themselves
      if (p.id == playerId) return true;

      // If this player is a rejoin of the target player
      if (p.originalPlayerId == playerId) return true;

      // If they share the same original player
      if (p.originalPlayerId != null &&
          p.originalPlayerId ==
              _currentGame!.players
                  .firstWhere((op) => op.id == playerId)
                  .originalPlayerId) return true;

      return false;
    }).toList();

    print('Related players for ID $playerId:');
    for (var p in relatedPlayers) {
      print(
          '- ${p.name} (ID: ${p.id}, Original ID: ${p.originalPlayerId}, Settled: ${p.isSettled})');
    }

    // Check if any related player has an active session
    return relatedPlayers.any((p) => !p.isSettled);
  }

  Future<void> handleRejoin(String playerId) async {
    try {
      if (_currentGame == null) throw Exception('No active game');
      _setLoading(true);

      print('Handling rejoin for player ID: $playerId');

      // Find the original player who wants to rejoin
      final settledPlayer = _currentGame!.players.firstWhere(
        (p) => p.id == playerId && p.isSettled,
        orElse: () => throw Exception('Player not found or not settled'),
      );

      // Check for any active related sessions
      if (hasActiveRelatedSessions(playerId)) {
        throw Exception('Player already has an active session');
      }

      // Create rejoin player instance
      final rejoinPlayer = settledPlayer.createRejoin();

      print('Creating rejoin player:');
      print('Original ID: ${rejoinPlayer.originalPlayerId}');
      print('New Player ID: ${rejoinPlayer.id}');
      print('Player Name: ${rejoinPlayer.name}');
      print('Rejoin Count: ${rejoinPlayer.rejoinCount}');

      await _repository.addPlayer(_currentGame!.id, rejoinPlayer);

      // Add initial buy-in transaction
      final transaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: rejoinPlayer.id,
        type: TransactionType.buyIn,
        amount: _currentGame!.buyInAmount,
        timestamp: DateTime.now(),
        note: 'Rejoin session initial buy-in',
      );

      await _repository.addTransaction(_currentGame!.id, transaction);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlayer(BuildContext context, Player player) async {
    try {
      if (_currentGame == null) throw Exception('No active game');
      _setLoading(true);

      // If this is a new player (not a rejoin), check if they share name with any existing player
      if (player.originalPlayerId == null) {
        final existingPlayer = _currentGame!.players
            .firstWhereOrNull((p) => p.name == player.name);

        if (existingPlayer != null) {
          final action = await _showDuplicateNameDialog(context, player.name);
          if (action == 'change') {
            final newName = await _showChangeNameDialog(context);
            if (newName != null && newName.isNotEmpty) {
              player = player.copyWith(name: newName);
            } else {
              throw Exception('Player name cannot be empty');
            }
          } else if (action == 'rejoin') {
            if (!existingPlayer.isSettled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Player must be settled before rejoining'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Check for active related sessions before allowing rejoin
            if (hasActiveRelatedSessions(existingPlayer.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This player already has an active session'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            player = existingPlayer.createRejoin();
          } else {
            throw Exception('Action cancelled');
          }
        }
      }

      await _repository.addPlayer(_currentGame!.id, player);
      _currentGame = await _repository.getGame(_currentGame!.id).first;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _showDuplicateNameDialog(
      BuildContext context, String name) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        title: Text(
          'Duplicate Name',
          style: AppTextStyles.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'A player with the name "$name" already exists.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'change'),
            child: Text(
              'Change Name',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'rejoin'),
            child: Text(
              'Rejoin',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showChangeNameDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        title: Text(
          'Change Name',
          style: AppTextStyles.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> addTransaction(PokerTransaction transaction) async {
    try {
      if (_currentGame == null) throw Exception('No active game');
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
      if (_currentGame == null) throw Exception('No active game');
      _setLoading(true);

      final transaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: playerId,
        type: TransactionType.reEntry,
        amount: _currentGame!.buyInAmount, // Always use game's buy-in amount
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

  Future<void> removeEntry(String playerId) async {
    try {
      if (_currentGame == null) throw Exception('No active game');
      _setLoading(true);
      _clearError();

      // Find the player
      final player = _currentGame!.players.firstWhere(
        (p) => p.id == playerId,
        orElse: () => throw Exception('Player not found in this game'),
      );

      // Validate player state
      if (player.isSettled) {
        throw Exception('Cannot remove entry from a settled player');
      }

      if (player.buyIns <= 1) {
        throw Exception(
            'Cannot remove the initial buy-in. Delete player instead.');
      }

      // Create a transaction to record the removal
      final transaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: playerId,
        type:
            TransactionType.reEntry, // Using reEntry type with negative amount
        amount: -_currentGame!.buyInAmount, // Negative amount to remove buy-in
        timestamp: DateTime.now(),
        note: 'Remove entry',
      );

      await addTransaction(transaction);

      // The game state will be automatically updated through the stream
      // since addTransaction triggers a database update
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> handleLoan({
    required String lenderId,
    required String recipientId,
    required double amount,
  }) async {
    try {
      if (_currentGame == null) throw Exception('No active game');

      final lender = _currentGame!.players.firstWhere(
        (p) => p.id == lenderId,
        orElse: () => throw Exception('Lender not found in this game'),
      );

      final recipient = _currentGame!.players.firstWhere(
        (p) => p.id == recipientId,
        orElse: () => throw Exception('Recipient not found in this game'),
      );

      final lenderTransaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: lenderId,
        type: TransactionType.loan,
        amount: -amount,
        timestamp: DateTime.now(),
        note: 'Loan to ${recipient.name}',
        relatedPlayerId: recipientId,
      );

      final recipientTransaction = PokerTransaction(
        id: const Uuid().v4(),
        playerId: recipientId,
        type: TransactionType.loan,
        amount: amount,
        timestamp: DateTime.now(),
        note: 'Loan from ${lender.name}',
        relatedPlayerId: lenderId,
      );

      await addTransaction(lenderTransaction);
      await addTransaction(recipientTransaction);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> settlePlayer(String playerId, double amount) async {
    try {
      if (_currentGame == null) throw Exception('No active game');
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
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Game> settleAllAndEnd() async {
    try {
      if (_currentGame == null) throw Exception('No active game');
      _setLoading(true);

      if (!_currentGame!.players.every((p) => p.isSettled)) {
        throw Exception('All players must be settled before ending the game');
      }

      await _repository.endGame(_currentGame!.id);
      final endedGame = _currentGame!.copyWith(
        isActive: false,
        endedAt: DateTime.now(),
      );

      _currentGame = null;
      _currentGameSubscription?.cancel();

      notifyListeners();
      return endedGame;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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

  Future<void> deleteGame(String gameId) async {
    try {
      _setLoading(true);
      _clearError();

      await _repository.deleteGame(gameId);

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

  List<Map<String, dynamic>> calculateSettlements() {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    final settlements = <Map<String, dynamic>>[];
    final balances = <String, double>{};

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

      final amount = debtor.value.abs() < creditor.value.abs()
          ? debtor.value.abs()
          : creditor.value.abs();

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

  Future<void> _showAddPlayerDialog(BuildContext context) async {
    final nameController = TextEditingController();

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        title: Text(
          'Add Player',
          style: AppTextStyles.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Player Name',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentGameSubscription?.cancel();
    _activeGamesSubscription?.cancel();
    _gameHistorySubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
