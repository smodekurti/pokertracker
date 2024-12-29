class Player {
  final String id;
  final String name;
  final String baseName; // New field
  final int buyIns;
  final double loans;
  final double? cashOut;
  final bool isSettled;
  final int rejoinCount; // New field to track number of rejoins
  final String?
      originalPlayerId; // Reference to original player if this is a rejoin
  final int previousBuyIns;
  final double previousLoans;
  final double? previousCashOut;

  const Player({
    required this.id,
    required this.name,
    String? baseName, // Optional parameter that defaults to name
    this.buyIns = 1,
    this.loans = 0,
    this.cashOut,
    this.isSettled = false,
    this.rejoinCount = 0,
    this.originalPlayerId,
    this.previousBuyIns = 0,
    this.previousLoans = 0,
    this.previousCashOut,
  }) : baseName = baseName ?? name; // Use name as baseName if not provided

  double calculateTotalIn(double buyInAmount) {
    return (buyIns * buyInAmount) + loans;
  }

  Player copyWith({
    String? id,
    String? name,
    String? baseName,
    int? buyIns,
    double? loans,
    double? cashOut,
    bool? isSettled,
    int? rejoinCount,
    String? originalPlayerId,
    int? previousBuyIns,
    double? previousLoans,
    double? previousCashOut,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      baseName: baseName ?? this.baseName,
      buyIns: buyIns ?? this.buyIns,
      loans: loans ?? this.loans,
      cashOut: cashOut ?? this.cashOut,
      isSettled: isSettled ?? this.isSettled,
      rejoinCount: rejoinCount ?? this.rejoinCount,
      originalPlayerId: originalPlayerId ?? this.originalPlayerId,
      previousBuyIns: previousBuyIns ?? this.previousBuyIns,
      previousLoans: previousLoans ?? this.previousLoans,
      previousCashOut: previousCashOut ?? this.previousCashOut,
    );
  }

  // Add method to create a rejoin instance
  Player createRejoin() {
    if (!isSettled) {
      throw Exception('Player must be settled before rejoining.');
    }
    final originalId = originalPlayerId ?? id;
    final newRejoinCount = rejoinCount + 1;
    return copyWith(
      id: '${originalId}_rejoin_${DateTime.now().millisecondsSinceEpoch}',
      name: '$baseName (Rejoin $newRejoinCount)',
      rejoinCount: newRejoinCount,
      originalPlayerId: originalId,
      isSettled: false,
      cashOut: null,
      buyIns: 1,
      loans: 0,
      previousBuyIns: buyIns,
      previousLoans: loans,
      previousCashOut: cashOut,
    );
  }

  // Add loansDetails getter
  List<LoanDetail> get loansDetails {
    // This should return a list of LoanDetail objects
    // For now, returning an empty list as a placeholder
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseName': baseName,
      'buyIns': buyIns,
      'loans': loans,
      'cashOut': cashOut,
      'isSettled': isSettled,
      'rejoinCount': rejoinCount,
      'originalPlayerId': originalPlayerId,
      'previousBuyIns': previousBuyIns,
      'previousLoans': previousLoans,
      'previousCashOut': previousCashOut,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      // Handle backward compatibility for baseName
      baseName: (map['baseName'] as String?) ?? map['name'] as String,
      buyIns: map['buyIns'] as int? ?? 1,
      loans: (map['loans'] as num?)?.toDouble() ?? 0.0,
      cashOut: (map['cashOut'] as num?)?.toDouble(),
      isSettled: map['isSettled'] as bool? ?? false,
      rejoinCount: map['rejoinCount'] as int? ?? 0,
      originalPlayerId: map['originalPlayerId'] as String?,
      previousBuyIns: map['previousBuyIns'] as int? ?? 0,
      previousLoans: (map['previousLoans'] as num?)?.toDouble() ?? 0.0,
      previousCashOut: (map['previousCashOut'] as num?)?.toDouble(),
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) => Player.fromMap(json);

  double calculateTotalWinnings(double buyInAmount) {
    if (!isSettled) return 0;

    double totalWinnings = 0;

    // Calculate current session winnings
    final currentTotalIn = calculateTotalIn(buyInAmount);
    final currentWinnings = (cashOut ?? 0) - currentTotalIn;
    totalWinnings += currentWinnings;

    // Add previous session winnings if this is a rejoin
    if (rejoinCount > 0 && previousCashOut != null) {
      final previousTotalIn = (previousBuyIns * buyInAmount) + previousLoans;
      final previousWinnings = previousCashOut! - previousTotalIn;
      totalWinnings += previousWinnings;
    }

    return totalWinnings;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.id == id &&
        other.name == name &&
        other.baseName == baseName &&
        other.buyIns == buyIns &&
        other.loans == loans &&
        other.cashOut == cashOut &&
        other.isSettled == isSettled &&
        other.rejoinCount == rejoinCount &&
        other.originalPlayerId == originalPlayerId &&
        other.previousBuyIns == previousBuyIns &&
        other.previousLoans == previousLoans &&
        other.previousCashOut == previousCashOut;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        baseName.hashCode ^
        buyIns.hashCode ^
        loans.hashCode ^
        cashOut.hashCode ^
        isSettled.hashCode ^
        rejoinCount.hashCode ^
        originalPlayerId.hashCode ^
        previousBuyIns.hashCode ^
        previousLoans.hashCode ^
        previousCashOut.hashCode;
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, baseName: $baseName, buyIns: $buyIns, loans: $loans, cashOut: $cashOut, isSettled: $isSettled, rejoinCount: $rejoinCount, originalPlayerId: $originalPlayerId, previousBuyIns: $previousBuyIns, previousLoans: $previousLoans, previousCashOut: $previousCashOut)';
  }
}

class LoanDetail {
  final String lenderId;
  final double amount;

  LoanDetail({required this.lenderId, required this.amount});
}

extension PlayerExtensions on Player {
  bool get hasUnsettledLoans {
    // Implement your loan checking logic here
    // For now, returning false as default
    return false;
  }
}
