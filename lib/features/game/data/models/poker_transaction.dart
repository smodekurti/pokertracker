// lib/features/game/data/models/poker_transaction.dart

import 'package:flutter/foundation.dart';

enum TransactionType { buyIn, reEntry, loan, settlement }

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.buyIn:
        return 'Buy-in';
      case TransactionType.reEntry:
        return 'Re-entry';
      case TransactionType.loan:
        return 'Loan';
      case TransactionType.settlement:
        return 'Settlement';
    }
  }

  String get description {
    switch (this) {
      case TransactionType.buyIn:
        return 'Initial buy-in to the game';
      case TransactionType.reEntry:
        return 'Additional buy-in during the game';
      case TransactionType.loan:
        return 'Loan between players';
      case TransactionType.settlement:
        return 'Final settlement amount';
    }
  }

  bool get affectsBalance {
    switch (this) {
      case TransactionType.buyIn:
      case TransactionType.reEntry:
      case TransactionType.loan:
        return true;
      case TransactionType.settlement:
        return false;
    }
  }
}

@immutable
class PokerTransaction {
  final String id;
  final String playerId;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final String? note;
  final String? relatedPlayerId;
  final bool isReverted;
  final String? revertedBy;
  final DateTime? revertedAt;

  const PokerTransaction({
    required this.id,
    required this.playerId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
    this.relatedPlayerId,
    this.isReverted = false,
    this.revertedBy,
    this.revertedAt,
  });

  // Factory constructor for initial buy-in
  factory PokerTransaction.buyIn({
    required String id,
    required String playerId,
    required double amount,
    String? note,
  }) {
    return PokerTransaction(
      id: id,
      playerId: playerId,
      type: TransactionType.buyIn,
      amount: amount,
      timestamp: DateTime.now(),
      note: note ?? 'Initial buy-in',
    );
  }

  // Factory constructor for re-entry
  factory PokerTransaction.reEntry({
    required String id,
    required String playerId,
    required double amount,
    String? note,
  }) {
    return PokerTransaction(
      id: id,
      playerId: playerId,
      type: TransactionType.reEntry,
      amount: amount,
      timestamp: DateTime.now(),
      note: note ?? 'Re-entry',
    );
  }

  // Factory constructor for loan
  factory PokerTransaction.loan({
    required String id,
    required String playerId,
    required String loanedByPlayerId,
    required double amount,
    String? note,
  }) {
    return PokerTransaction(
      id: id,
      playerId: playerId,
      type: TransactionType.loan,
      amount: amount,
      timestamp: DateTime.now(),
      note: note ?? 'Loan from player',
      relatedPlayerId: loanedByPlayerId,
    );
  }

  // Factory constructor for settlement
  factory PokerTransaction.settlement({
    required String id,
    required String playerId,
    required double amount,
    String? note,
  }) {
    return PokerTransaction(
      id: id,
      playerId: playerId,
      type: TransactionType.settlement,
      amount: amount,
      timestamp: DateTime.now(),
      note: note ?? 'Final settlement',
    );
  }

  // Create a copy of this transaction with revert information
  PokerTransaction revert(String revertedById) {
    return copyWith(
      isReverted: true,
      revertedBy: revertedById,
      revertedAt: DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'type': type.toString(),
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'relatedPlayerId': relatedPlayerId,
      'isReverted': isReverted,
      'revertedBy': revertedBy,
      'revertedAt': revertedAt?.toIso8601String(),
    };
  }

  // Create from Map from Firestore
  factory PokerTransaction.fromMap(Map<String, dynamic> map) {
    return PokerTransaction(
      id: map['id'],
      playerId: map['playerId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      amount: map['amount'].toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      note: map['note'],
      relatedPlayerId: map['relatedPlayerId'],
      isReverted: map['isReverted'] ?? false,
      revertedBy: map['revertedBy'],
      revertedAt:
          map['revertedAt'] != null ? DateTime.parse(map['revertedAt']) : null,
    );
  }

  // Create a copy with some fields updated
  PokerTransaction copyWith({
    String? id,
    String? playerId,
    TransactionType? type,
    double? amount,
    DateTime? timestamp,
    String? note,
    String? relatedPlayerId,
    bool? isReverted,
    String? revertedBy,
    DateTime? revertedAt,
  }) {
    return PokerTransaction(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      relatedPlayerId: relatedPlayerId ?? this.relatedPlayerId,
      isReverted: isReverted ?? this.isReverted,
      revertedBy: revertedBy ?? this.revertedBy,
      revertedAt: revertedAt ?? this.revertedAt,
    );
  }

  // For debugging
  @override
  String toString() {
    return 'PokerTransaction(id: $id, playerId: $playerId, type: ${type.name}, '
        'amount: $amount, timestamp: $timestamp, note: $note)';
  }

  // Equatable override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PokerTransaction &&
        other.id == id &&
        other.playerId == playerId &&
        other.type == type &&
        other.amount == amount &&
        other.timestamp == timestamp &&
        other.note == note &&
        other.relatedPlayerId == relatedPlayerId &&
        other.isReverted == isReverted &&
        other.revertedBy == revertedBy &&
        other.revertedAt == revertedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        playerId.hashCode ^
        type.hashCode ^
        amount.hashCode ^
        timestamp.hashCode ^
        note.hashCode ^
        relatedPlayerId.hashCode ^
        isReverted.hashCode ^
        revertedBy.hashCode ^
        revertedAt.hashCode;
  }

  factory PokerTransaction.fromJson(Map<String, dynamic> json) {
    return PokerTransaction(
      id: json['id'] as String,
      playerId: json['playerId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'] as String?,
      relatedPlayerId: json['relatedPlayerId'] as String?,
      isReverted: json['isReverted'] as bool? ?? false,
      revertedBy: json['revertedBy'] as String?,
      revertedAt: json['revertedAt'] != null
          ? DateTime.parse(json['revertedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  // Validation methods
  bool get isValid {
    return id.isNotEmpty &&
        playerId.isNotEmpty &&
        amount > 0 &&
        _isValidLoanTransaction;
  }

  bool get _isValidLoanTransaction {
    if (type == TransactionType.loan) {
      return relatedPlayerId != null && relatedPlayerId != playerId;
    }
    return true;
  }

  // Helper methods
  bool get canBeReverted {
    return !isReverted && type != TransactionType.settlement;
  }

  String get displayAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String get displayTimestamp {
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} '
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // For sorting
  static int compareByTimestamp(PokerTransaction a, PokerTransaction b) {
    return b.timestamp.compareTo(a.timestamp);
  }

  static int compareByAmount(PokerTransaction a, PokerTransaction b) {
    return b.amount.compareTo(a.amount);
  }
}
