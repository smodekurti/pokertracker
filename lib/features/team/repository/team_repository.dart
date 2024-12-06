import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poker_tracker/features/team/data/team.dart';

class TeamRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  TeamRepository({required this.userId}) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
  }

  CollectionReference get _teamsCollection {
    return _db.collection('users').doc(userId).collection('teams');
  }

  Future<String> createTeam(Team team) async {
    try {
      final teamRef = _teamsCollection.doc();
      final teamData = {
        'id': teamRef.id,
        ...team.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await teamRef.set(teamData);
      return teamRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      // Get the document reference
      final docRef = _teamsCollection.doc(team.id);

      // Check if document exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Team not found in database');
      }

      // Prepare the update data
      final teamData = {
        'name': team.name,
        'players': team.players.map((p) => p.toMap()).toList(),
        // Don't update createdAt and createdBy as they should remain unchanged
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Perform the update
      await docRef.update(teamData);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> getTeams() {
    try {
      return _teamsCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure the ID is included in the data
          data['id'] = doc.id;
          return Team.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Team?> getTeamById(String teamId) async {
    try {
      final docSnapshot = await _teamsCollection.doc(teamId).get();
      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id; // Ensure ID is included
      return Team.fromFirestore(docSnapshot);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> teamExists(String teamId) async {
    try {
      final docSnapshot = await _teamsCollection.doc(teamId).get();
      return docSnapshot.exists;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
