class Player {
  final String id;
  final String name;
  final String baseName; // New field
  final int buyIns;
  final double loans;
  final double? cashOut;
  final bool isSettled;

  const Player({
    required this.id,
    required this.name,
    String? baseName, // Optional parameter that defaults to name
    this.buyIns = 1,
    this.loans = 0,
    this.cashOut,
    this.isSettled = false,
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
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      baseName: baseName ?? this.baseName,
      buyIns: buyIns ?? this.buyIns,
      loans: loans ?? this.loans,
      cashOut: cashOut ?? this.cashOut,
      isSettled: isSettled ?? this.isSettled,
    );
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
        other.isSettled == isSettled;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        baseName.hashCode ^
        buyIns.hashCode ^
        loans.hashCode ^
        cashOut.hashCode ^
        isSettled.hashCode;
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, baseName: $baseName, buyIns: $buyIns, loans: $loans, cashOut: $cashOut, isSettled: $isSettled)';
  }
}

extension PlayerExtensions on Player {
  bool get hasUnsettledLoans {
    // Implement your loan checking logic here
    // For now, returning false as default
    return false;
  }
}
