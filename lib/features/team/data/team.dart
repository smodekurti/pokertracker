import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Team {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final List<TeamPlayer> players;

  Team({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.players,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'players': players.map((p) => p.toMap()).toList(),
    };
  }

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Team(
      id: doc.id, // Always use the document ID
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      players: (data['players'] as List<dynamic>?)
              ?.map((p) => TeamPlayer.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Team copyWith({
    String? name,
    List<TeamPlayer>? players,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      createdAt: createdAt,
      players: players ?? this.players,
    );
  }
}

class TeamPlayer {
  final String id;
  final String name;

  TeamPlayer({
    String? id,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory TeamPlayer.fromMap(Map<String, dynamic> map) {
    return TeamPlayer(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
    );
  }
}
