import 'package:flutter/material.dart';

class SettlementState extends ChangeNotifier {
  final Map<String, double> settlements;
  final Set<String> _settledPlayers = {};
  final double totalPot;
  bool finalSettlement;

  SettlementState({
    required Map<String, double> settlements,
    required this.totalPot,
    this.finalSettlement = false,
  }) : settlements = Map.from(settlements) {
    // Initialize settled players from existing settlements
    for (var entry in settlements.entries) {
      if (entry.value != 0) {
        _settledPlayers.add(entry.key);
      }
    }
  }

  // New methods for tracking settled state
  void updateSettlement(String playerId, double amount,
      {bool isSettled = true}) {
    settlements[playerId] = amount;
    if (isSettled) {
      _settledPlayers.add(playerId);
    } else {
      _settledPlayers.remove(playerId);
    }
    notifyListeners();
  }

  bool isPlayerSettled(String playerId) => _settledPlayers.contains(playerId);

  double? getSettledAmount(String playerId) => settlements[playerId];

  // Existing functionality
  double get totalSettled =>
      settlements.values.fold(0, (sum, amount) => sum + amount);

  double get remaining => totalPot - totalSettled;

  bool get isTallied => (totalSettled - totalPot).abs() < 0.01;

  List<MapEntry<String, double>> get winners {
    return settlements.entries
        .where((entry) =>
            entry.value > getInitialAmount(totalPot, settlements.length))
        .toList();
  }

  List<MapEntry<String, double>> get losers {
    return settlements.entries
        .where((entry) =>
            entry.value < getInitialAmount(totalPot, settlements.length))
        .toList();
  }

  double getTotalWinnings() {
    return winners.fold(
        0.0,
        (sum, entry) =>
            sum +
            (entry.value - getInitialAmount(totalPot, settlements.length)));
  }

  double getTotalLosses() {
    return losers.fold(
        0.0,
        (sum, entry) =>
            sum +
            (getInitialAmount(totalPot, settlements.length) - entry.value));
  }

  double getInitialAmount(double totalPot, int playerCount) {
    return totalPot / playerCount;
  }

  bool isBalanced() {
    if (!isTallied) return false;
    final winningsTotal = getTotalWinnings();
    final lossesTotal = getTotalLosses();
    return (winningsTotal - lossesTotal).abs() < 0.01;
  }

  // Helper method to check if all players are settled
  bool get allPlayersSettled =>
      settlements.length == _settledPlayers.length && settlements.isNotEmpty;
}
