import 'package:poker_tracker/features/team/data/team.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

import '../../../core/database/database_helper.dart';

class TeamRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final String userId;
  final _teamsController = StreamController<List<Team>>.broadcast();
  Timer? _refreshTimer;

  TeamRepository({required this.userId}) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    // Simulate Firestore realtime updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshTeams();
    });
  }

  Stream<List<Team>> getTeams() {
    _refreshTeams();
    return _teamsController.stream;
  }

  Future<String> createTeam(Team team) async {
    final db = await _db.database;

    try {
      await db.transaction((txn) async {
        // First check if team name already exists for this user
        final existingTeam = await txn.query(
          DatabaseHelper.tableTeams,
          where: 'name = ? AND userId = ?',
          whereArgs: [team.name, userId],
        );

        if (existingTeam.isNotEmpty) {
          throw Exception('A team with this name already exists');
        }

        // Insert team
        await txn.insert(DatabaseHelper.tableTeams, {
          'id': team.id,
          'name': team.name,
          'createdBy': userId,
          'createdAt': team.createdAt.toIso8601String(),
          'userId': userId,
        });

        // Insert team players
        for (final player in team.players) {
          await txn.insert(DatabaseHelper.tableTeamPlayers, {
            'id': player.id,
            'teamId': team.id,
            'name': player.name,
          });
        }
      });

      _refreshTeams();
      return team.id;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('A team with this name already exists');
      }
      throw Exception('Failed to create team: ${e.toString()}');
    }
  }

  Future<void> updateTeam(Team team) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // Update team
      await txn.update(
        DatabaseHelper.tableTeams,
        {
          'name': team.name,
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [team.id, userId],
      );

      // Delete existing players
      await txn.delete(
        DatabaseHelper.tableTeamPlayers,
        where: 'teamId = ?',
        whereArgs: [team.id],
      );

      // Insert updated players
      for (final player in team.players) {
        await txn.insert(DatabaseHelper.tableTeamPlayers, {
          'id': player.id,
          'teamId': team.id,
          'name': player.name,
        });
      }
    });

    _refreshTeams();
  }

  Future<Team?> getTeamById(String teamId) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableTeams,
      where: 'id = ? AND userId = ?',
      whereArgs: [teamId, userId],
    );

    if (rows.isEmpty) return null;
    return _createTeamFromRow(db, rows.first);
  }

  Future<bool> teamExists(String teamId) async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(await db.query(
      DatabaseHelper.tableTeams,
      columns: ['COUNT(*)'],
      where: 'id = ? AND userId = ?',
      whereArgs: [teamId, userId],
    ));
    return (count ?? 0) > 0;
  }

  Future<void> deleteTeam(String teamId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableTeams,
      where: 'id = ? AND userId = ?',
      whereArgs: [teamId, userId],
    );
    _refreshTeams();
  }

  // Private helper methods
  Future<void> _refreshTeams() async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        DatabaseHelper.tableTeams,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      final teams = await Future.wait(
        rows.map((row) => _createTeamFromRow(db, row)),
      );

      _teamsController.add(teams);
    } catch (e) {
      _teamsController.addError(e);
    }
  }

  Future<Team> _createTeamFromRow(Database db, Map<String, dynamic> row) async {
    final playerRows = await db.query(
      DatabaseHelper.tableTeamPlayers,
      where: 'teamId = ?',
      whereArgs: [row['id']],
    );

    final players = playerRows
        .map((p) => TeamPlayer(
              id: p['id'] as String,
              name: p['name'] as String,
            ))
        .toList();

    return Team(
      id: row['id'],
      name: row['name'],
      createdBy: row['createdBy'],
      createdAt: DateTime.parse(row['createdAt']),
      players: players,
    );
  }

  void dispose() {
    _refreshTimer?.cancel();
    _teamsController.close();
  }
}
