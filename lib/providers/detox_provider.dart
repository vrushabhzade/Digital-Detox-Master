import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_detox_master/models/detox_models.dart';

class DetoxProvider extends ChangeNotifier {
  UserStats _stats = UserStats();
  List<Habit> _habits = [];
  bool _isLoading = true;

  UserStats get stats => _stats;
  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;

  DetoxProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load stats
      final statsString = prefs.getString('user_stats');
      if (statsString != null) {
        _stats = UserStats.fromJson(jsonDecode(statsString));
      }

      // Load habits
      final habitsString = prefs.getString('habits');
      if (habitsString != null) {
        final List<dynamic> jsonList = jsonDecode(habitsString);
        _habits = jsonList.map((e) => Habit.fromJson(e)).toList();
      } else {
        // Initial dummy habits
        _habits = [
          Habit(id: '1', title: 'Read 5 pages', category: 'Education', durationMinutes: 15),
          Habit(id: '2', title: 'Do 10 pushups', category: 'Health', durationMinutes: 5),
          Habit(id: '3', title: 'Meditate', category: 'Mindfulness', durationMinutes: 10),
        ];
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_stats', jsonEncode(_stats.toJson()));
      await prefs.setString('habits', jsonEncode(_habits.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  void completeHabit(String habitId) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1 && !_habits[index].isCompletedToday) {
      _habits[index].isCompletedToday = true;
      _stats.minutesSaved += _habits[index].durationMinutes;
      _stats.points += 10;
      _checkLevelUp();
      _saveData();
      notifyListeners();
    }
  }

  void _checkLevelUp() {
    // Simple level up logic: every 100 points
    final newLevel = (_stats.points / 100).floor() + 1;
    if (newLevel > _stats.level) {
      _stats.level = newLevel;
      // Could trigger a celebration event here
    }
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    _saveData();
    notifyListeners();
  }

  void resetDailyProgress() {
    for (var habit in _habits) {
      habit.isCompletedToday = false;
    }
    _saveData();
    notifyListeners();
  }
  
  // Call this periodically or on app start to check if it's a new day
  // For now, we'll just leave it manual or implement check later
}
