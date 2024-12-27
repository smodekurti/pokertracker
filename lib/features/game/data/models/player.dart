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
    );
  }

  // Add method to create a rejoin instance
  Player createRejoin() {
    final originalId = originalPlayerId ?? id;
    return copyWith(
      id: '${originalId}_rejoin_${DateTime.now().millisecondsSinceEpoch}',
      rejoinCount: rejoinCount + 1,
      originalPlayerId: originalId,
      isSettled: false,
      cashOut: null,
      buyIns: 1,
      loans: 0,
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
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) => Player.fromMap(json);

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
        other.originalPlayerId == originalPlayerId;
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
        originalPlayerId.hashCode;
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, baseName: $baseName, buyIns: $buyIns, loans: $loans, cashOut: $cashOut, isSettled: $isSettled, rejoinCount: $rejoinCount, originalPlayerId: $originalPlayerId)';
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
