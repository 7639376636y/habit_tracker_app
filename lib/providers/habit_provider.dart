import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/layout_settings.dart';
import '../services/habit_service.dart';

/// Habit limits based on subscription plan
class HabitLimits {
  final bool canCreate;
  final int current;
  final int max;
  final String plan;

  HabitLimits({
    this.canCreate = true,
    this.current = 0,
    this.max = 5,
    this.plan = 'free',
  });

  factory HabitLimits.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HabitLimits();
    return HabitLimits(
      canCreate: json['canCreate'] ?? true,
      current: json['current'] ?? 0,
      max: json['max'] ?? 5,
      plan: json['plan'] ?? 'free',
    );
  }
}

class HabitProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();

  int _selectedYear = 2026;
  int _selectedMonth = 1; // January
  List<Habit> _habits = [];
  LayoutSettings _layoutSettings = LayoutSettings.defaultSettings();
  bool _isLoading = false;
  bool _isInitialized = false;
  HabitLimits _limits = HabitLimits();

  HabitProvider();

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  List<Habit> get habits => _habits;
  LayoutSettings get layoutSettings => _layoutSettings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  HabitLimits get limits => _limits;

  // Initialize and load habits + layout settings from backend
  Future<void> initialize() async {
    if (_isInitialized) return;
    await Future.wait([_loadHabitsFromBackend(), loadLayoutSettings()]);
    _isInitialized = true;
  }

  // Force refresh habits from backend (for sync across devices)
  Future<void> refreshHabits() async {
    await _loadHabitsFromBackend();
  }

  // Force refresh all data from backend
  Future<void> refreshAll() async {
    await Future.wait([_loadHabitsFromBackend(), loadLayoutSettings()]);
  }

  // Internal method to load habits from backend
  Future<void> _loadHabitsFromBackend() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _habitService.getHabitsWithLimits();
      _habits = result['habits'] as List<Habit>;
      _limits = result['limits'] as HabitLimits;
    } catch (e) {
      debugPrint('Error loading habits from backend: $e');
      // Don't clear habits on error - keep existing data
    }

    _isLoading = false;
    notifyListeners();
  }

  // Check if user has any habits
  bool get hasHabits => _habits.isNotEmpty;

  // Check if user can create more habits
  bool get canCreateHabit => _limits.canCreate;

  // Reset when user logs out
  void reset() {
    _habits = [];
    _isInitialized = false;
    _limits = HabitLimits();
    _layoutSettings = LayoutSettings.defaultSettings();
    notifyListeners();
  }

  // ========== Layout Settings Methods ==========

  // Load layout settings from backend
  Future<void> loadLayoutSettings() async {
    try {
      final settings = await _habitService.getLayoutSettings();
      if (settings != null) {
        _layoutSettings = settings;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading layout settings: $e');
    }
  }

  // Save layout settings to backend
  Future<void> _saveLayoutSettings() async {
    try {
      await _habitService.saveLayoutSettings(_layoutSettings);
    } catch (e) {
      debugPrint('Error saving layout settings: $e');
    }
  }

  void updateLayoutSettings(LayoutSettings settings) {
    _layoutSettings = settings;
    notifyListeners();
    _saveLayoutSettings();
  }

  void toggleSectionVisibility(LayoutSection section) {
    final newVisibility = Map<LayoutSection, bool>.from(
      _layoutSettings.visibleSections,
    );
    newVisibility[section] = !(newVisibility[section] ?? true);
    _layoutSettings = _layoutSettings.copyWith(visibleSections: newVisibility);
    notifyListeners();
    _saveLayoutSettings();
  }

  void reorderSections(int oldIndex, int newIndex) {
    final newOrder = List<LayoutSection>.from(_layoutSettings.sectionOrder);
    if (newIndex > oldIndex) newIndex--;
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    _layoutSettings = _layoutSettings.copyWith(sectionOrder: newOrder);
    notifyListeners();
    _saveLayoutSettings();
  }

  void setDesktopColumns(int columns) {
    _layoutSettings = _layoutSettings.copyWith(columnsDesktop: columns);
    notifyListeners();
    _saveLayoutSettings();
  }

  void setTabletColumns(int columns) {
    _layoutSettings = _layoutSettings.copyWith(columnsTablet: columns);
    notifyListeners();
    _saveLayoutSettings();
  }

  Future<void> resetLayoutSettings() async {
    _layoutSettings = LayoutSettings.defaultSettings();
    notifyListeners();
    await _saveLayoutSettings();
  }

  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> toggleHabitDay(int habitId, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];

      // Optimistically update UI
      _habits[index] = habit.toggleDay(date);
      notifyListeners();

      // Sync with backend if we have a mongoId
      if (habit.mongoId != null) {
        final updatedHabit = await _habitService.toggleDay(
          habit.mongoId!,
          date,
        );
        if (updatedHabit != null) {
          _habits[index] = updatedHabit;
          notifyListeners();
        }
      }
    }
  }

  Future<void> addHabit(
    String name,
    int goalDays, {
    String? description,
    HabitCategory? category,
    String? color,
    String? icon,
  }) async {
    // Check limits first
    if (!_limits.canCreate) {
      throw Exception('Habit limit reached. Upgrade to create more habits.');
    }

    // Create on backend - NO local fallback to ensure data is synced
    final result = await _habitService.createHabit(
      name,
      goalDays,
      description: description,
      category: category?.name.toUpperCase(),
      color: color,
      icon: icon,
    );

    if (result != null) {
      _habits.add(result['habit'] as Habit);
      if (result['limits'] != null) {
        _limits = result['limits'] as HabitLimits;
      }
      notifyListeners();
    } else {
      // Throw error instead of local fallback - ensures data is always in DB
      throw Exception('Failed to create habit. Please check your connection.');
    }
  }

  Future<void> archiveHabit(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1) return;

    if (habit.mongoId != null) {
      final success = await _habitService.archiveHabit(habit.mongoId!);
      if (success) {
        _habits.removeWhere((h) => h.id == habitId);
        notifyListeners();
      }
    }
  }

  Future<void> removeHabit(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1) return;

    // Optimistically update UI
    _habits.removeWhere((h) => h.id == habitId);
    notifyListeners();

    // Delete from backend
    if (habit.mongoId != null) {
      await _habitService.deleteHabit(habit.mongoId!);
    }
  }

  Future<void> updateHabit(int habitId, String name, int goalDays) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];

      // Optimistically update UI
      _habits[index] = habit.copyWith(name: name, goalDays: goalDays);
      notifyListeners();

      // Sync with backend
      if (habit.mongoId != null) {
        await _habitService.updateHabit(habit.mongoId!, name, goalDays);
      }
    }
  }

  // Get days in current month
  int get daysInMonth {
    return DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  // Get first day of month (weekday)
  int get firstDayOfMonth {
    return DateTime(_selectedYear, _selectedMonth, 1).weekday;
  }

  // Get all dates for the current month
  List<DateTime> get monthDates {
    final days = daysInMonth;
    return List.generate(
      days,
      (index) => DateTime(_selectedYear, _selectedMonth, index + 1),
    );
  }

  // Get weeks for the current month
  List<List<DateTime>> get weeksInMonth {
    final dates = monthDates;
    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];

    for (final date in dates) {
      currentWeek.add(date);
      if (date.weekday == DateTime.sunday || date == dates.last) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    return weeks;
  }

  // Calculate total completed for a specific day across all habits
  int completedOnDay(DateTime date) {
    return _habits.where((h) => h.isCompletedOn(date)).length;
  }

  // Calculate overall progress for a week
  Map<String, dynamic> weekProgress(List<DateTime> weekDates) {
    int completed = 0;
    int goal = _habits.length * weekDates.length;

    for (final date in weekDates) {
      completed += completedOnDay(date);
    }

    return {
      'completed': completed,
      'goal': goal,
      'left': goal - completed,
      'percentage': goal > 0 ? (completed / goal) * 100 : 0.0,
    };
  }

  // Get overall monthly progress
  Map<String, dynamic> get monthlyProgress {
    int totalCompleted = 0;
    int totalGoal = 0;

    for (final habit in _habits) {
      totalGoal += habit.goalDays;
      for (final date in monthDates) {
        if (habit.isCompletedOn(date)) {
          totalCompleted++;
        }
      }
    }

    return {
      'completed': totalCompleted,
      'goal': totalGoal,
      'left': totalGoal - totalCompleted,
      'percentage': totalGoal > 0 ? (totalCompleted / totalGoal) * 100 : 0.0,
    };
  }

  // Get daily progress data for chart
  List<double> get dailyProgressData {
    return monthDates.map((date) {
      final completed = completedOnDay(date);
      final total = _habits.length;
      return total > 0 ? (completed / total) * 100 : 0.0;
    }).toList();
  }

  // Get top habits by completion
  List<Habit> get topHabits {
    final sorted = List<Habit>.from(_habits);
    sorted.sort((a, b) => b.completedCount.compareTo(a.completedCount));
    return sorted.take(10).toList();
  }

  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[_selectedMonth - 1];
  }
}
