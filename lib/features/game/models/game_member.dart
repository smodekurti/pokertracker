class GameMember {
  // ...existing code...
  static const double defaultBuyInAmount = 20.0;
  final double buyInAmount = defaultBuyInAmount; // Fixed buy-in amount
  // ...existing code...

  Map<String, dynamic> toMap() {
    return {
      // ...existing code...
      'buyInAmount': defaultBuyInAmount,
      // ...existing code...
    };
  }
}
