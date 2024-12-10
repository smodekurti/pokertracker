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
    _teamsSubscription?.cancel();
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
    try {
      return _teams.firstWhere((team) => team.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createTeam(String name, List<TeamPlayer> players) async {
    try {
      _setLoading(true);
      _clearError();

      if (name.trim().isEmpty) {
        throw Exception('Team name cannot be empty');
      }

      if (players.isEmpty) {
        throw Exception('Team must have at least one player');
      }

      final team = Team(
        id: const Uuid().v4(),
        name: name.trim(),
        createdAt: DateTime.now(),
        createdBy: _repository.userId,
        players: players,
      );

      await _repository.createTeam(team);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      _setLoading(true);
      _clearError();

      final exists = await _repository.teamExists(team.id);
      if (!exists) {
        throw Exception('Team not found. It might have been deleted.');
      }
      await _repository.updateTeam(team);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      _setLoading(true);
      _clearError();
      await _repository.deleteTeam(teamId);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshTeams() async {
    try {
      _setLoading(true);
      _clearError();

      // Cancel existing subscription
      await _teamsSubscription?.cancel();

      // Reinitialize stream
      _initializeStream();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _teamsSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
