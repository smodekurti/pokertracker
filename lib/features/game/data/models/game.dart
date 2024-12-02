// lib/features/game/data/models/game.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/poker_transaction.dart';

class Game {
  final String id;
  String name;
  DateTime date;
  List<Player> players;
  List<PokerTransaction> transactions;
  bool isActive;
  final String createdBy;
  final DateTime createdAt;
  DateTime? endedAt;
  double buyInAmount;
  double cutPercentage; // New field

  Game({
    required this.id,
    required this.name,
    required this.date,
    required this.players,
    required this.createdBy,
    required this.buyInAmount,
    this.transactions = const [],
    this.isActive = true,
    required this.createdAt,
    this.endedAt,
    this.cutPercentage = 0, // Default to 0% cut
  });

  // Calculate total pot including all buy-ins, re-entries, and loans
  double get totalPot {
    double total = 0;
    total +=
        players.fold(0.0, (sum, player) => sum + (player.buyIns * buyInAmount));
    total += players.fold(0.0, (sum, player) => sum + player.loans);
    return total;
  }

  // Calculate cut amount
  double get cutAmount {
    return totalPot * (cutPercentage / 100);
  }

  // Calculate player's net amount considering the cut
  double getPlayerNetAmount(String playerId) {
    // Apply cut to the net amount (whether positive or negative)
    return getPlayerOriginalAmount(playerId) * (1 - (cutPercentage / 100));
  }

  // Calculate player's original amount before cut
  double getPlayerOriginalAmount(String playerId) {
    final player = players.firstWhere((p) => p.id == playerId);
    if (!player.isSettled) return 0;

    final totalIn = (player.buyIns * buyInAmount) + player.loans;
    return (player.cashOut ?? 0) - totalIn;
  }

  // Verify if settlements are balanced
  bool get isSettlementBalanced {
    if (!players.every((p) => p.isSettled)) return false;

    final totalWinnings = players
        .where((p) => getPlayerOriginalAmount(p.id) > 0)
        .fold(0.0, (sum, player) => sum + getPlayerOriginalAmount(player.id));

    final totalLosses = players
        .where((p) => getPlayerOriginalAmount(p.id) < 0)
        .fold(0.0,
            (sum, player) => sum + getPlayerOriginalAmount(player.id).abs());

    return (totalWinnings - totalLosses).abs() <
        0.01; // Account for floating point precision
  }

  // Get actual pot after cut
  double get actualPot {
    return totalPot * (1 - (cutPercentage / 100));
  }

  // Calculate active pot (excluding settled players)
  double get activePot {
    double total = 0;

    for (final player in players) {
      if (!player.isSettled) {
        total += (player.buyIns * buyInAmount) + player.loans;
      }
    }

    return total;
  }

  // Calculate total amount in play (including cash outs)
  double get totalAmountInPlay {
    double total = totalPot;

    // Add all cash outs
    total += players.fold(0.0, (sum, player) => sum + (player.cashOut ?? 0));

    return total;
  }

  // Check if pot is balanced (total cash outs equal total pot)
  bool get isPotBalanced {
    if (!players.every((p) => p.isSettled)) return false;

    final totalCashOut =
        players.fold(0.0, (sum, player) => sum + (player.cashOut ?? 0));

    return (totalCashOut - totalPot).abs() <
        0.01; // Account for floating point precision
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'players': players.map((p) => p.toMap()).toList(),
      'createdBy': createdBy,
      'buyInAmount': buyInAmount,
      'cutPercentage': cutPercentage,
      'isActive': isActive,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Game(
      id: doc.id, // Always use document ID
      name: data['name'] ?? '',
      date: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      players: (data['players'] as List<dynamic>?)
              ?.map((p) => Player.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: data['createdBy'] ?? '',
      buyInAmount: (data['buyInAmount'] as num?)?.toDouble() ?? 0.0,
      cutPercentage: (data['cutPercentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as Timestamp).toDate()
          : null,
      transactions: (data['transactions'] as List<dynamic>?)
              ?.map((t) => PokerTransaction.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Create a copy with some fields updated
// In Game model
  Game copyWith({
    String? id,
    String? name,
    DateTime? date,
    List<Player>? players,
    String? createdBy,
    double? buyInAmount,
    double? cutPercentage,
    DateTime? createdAt,
    DateTime? endedAt,
    bool? isActive,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      players: players ?? this.players,
      createdBy: createdBy ?? this.createdBy,
      buyInAmount: buyInAmount ?? this.buyInAmount,
      cutPercentage: cutPercentage ?? this.cutPercentage,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    try {
      return Game(
        id: json['id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date']),
        players: (json['players'] as List?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        transactions: (json['transactions'] as List?)
                ?.map(
                    (t) => PokerTransaction.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        createdBy: json['createdBy'] as String,
        buyInAmount: (json['buyInAmount'] as num?)?.toDouble() ?? 0.0,
        cutPercentage: (json['cutPercentage'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] is Timestamp
                ? (json['createdAt'] as Timestamp).toDate()
                : DateTime.parse(json['createdAt']))
            : DateTime.now(),
        endedAt: json['endedAt'] != null
            ? (json['endedAt'] is Timestamp
                ? (json['endedAt'] as Timestamp).toDate()
                : DateTime.parse(json['endedAt']))
            : null,
      );
    } catch (e) {
      print('Error parsing game JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => toMap();

  // Helper methods
  Player? getPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  List<PokerTransaction> getPlayerTransactions(String playerId) {
    return transactions
        .where((t) => t.playerId == playerId && !t.isReverted)
        .toList();
  }

  bool hasUnsettledLoans() {
    return players.any((p) => p.loans > 0 && !p.isSettled);
  }

  // For debugging
  @override
  String toString() {
    return 'Game(id: $id, name: $name, players: ${players.length}, '
        'totalPot: $totalPot, active: $isActive)';
  }
}
