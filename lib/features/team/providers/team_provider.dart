import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:poker_tracker/features/team/data/team.dart';
import 'package:poker_tracker/features/team/repository/team_repository.dart';
import 'package:uuid/uuid.dart';

class TeamProvider with ChangeNotifier {
  final TeamRepository _repository;
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _teamsSubscription;

  TeamProvider(String userId) : _repository = TeamRepository(userId: userId) {
    _initializeStream();
  }

  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initializeStream() {
    _teamsSubscription = _repository.getTeams().listen(
      (teams) {
        _teams = teams;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Team? getTeamById(String id) {
    return _teams.firstWhere(
      (team) => team.id == id,
      orElse: () => throw Exception('Team not found'),
    );
  }

  Future<void> createTeam(String name, List<TeamPlayer> players) async {
    try {
      _isLoading = true;
      notifyListeners();

      final team = Team(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now(),
        createdBy: _repository.userId,
        players: players,
      );

      await _repository.createTeam(team);
    } catch (e) {
      _error = e.toString();
      rethrow; // Rethrow to handle in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      _isLoading = true;
      notifyListeners();

      final exists = await _repository.teamExists(team.id);
      if (!exists) {
        throw Exception('Team not found. It might have been deleted.');
      }
      await _repository.updateTeam(team);
    } catch (e) {
      _error = e.toString();
      rethrow; // Rethrow to handle in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.deleteTeam(teamId);
    } catch (e) {
      _error = e.toString();
      rethrow; // Rethrow to handle in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTeams() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cancel existing subscription
      await _teamsSubscription?.cancel();

      // Reinitialize stream
      _initializeStream();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _teamsSubscription?.cancel();
    super.dispose();
  }
}
