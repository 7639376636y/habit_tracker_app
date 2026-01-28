import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/layout_settings.dart';
import '../services/habit_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();

  int _selectedYear = 2026;
  int _selectedMonth = 1; // January
  List<Habit> _habits = [];
  LayoutSettings _layoutSettings = LayoutSettings.defaultSettings();
  bool _isLoading = false;
  bool _isInitialized = false;

  HabitProvider();

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  List<Habit> get habits => _habits;
  LayoutSettings get layoutSettings => _layoutSettings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Initialize and load habits from backend
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _habits = await _habitService.getHabits();
      if (_habits.isEmpty) {
        // If no habits from backend, create default habits
        await _createDefaultHabits();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing habits: $e');
      _initializeDefaultHabitsLocal();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create default habits on backend
  Future<void> _createDefaultHabits() async {
    final defaultHabits = [
      {'name': 'Prayer x5', 'goalDays': 30},
      {'name': 'Morning food take Fruits', 'goalDays': 30},
      {'name': 'Nuts & Dry Fruits (Limits)', 'goalDays': 30},
      {'name': 'Running', 'goalDays': 30},
      {'name': '10000+ Steps', 'goalDays': 30},
      {'name': 'Chicken without Oil', 'goalDays': 30},
      {'name': '11 PM Sleep', 'goalDays': 30},
      {'name': 'Wake-up 7 AM', 'goalDays': 30},
      {'name': 'Any Hard Workout', 'goalDays': 30},
      {'name': 'No - Sugar', 'goalDays': 30},
      {'name': 'No - Junk food / Fast Food', 'goalDays': 30},
      {'name': 'No - Snacks', 'goalDays': 30},
      {'name': 'No - M&M', 'goalDays': 26},
    ];

    for (final habitData in defaultHabits) {
      final habit = await _habitService.createHabit(
        habitData['name'] as String,
        habitData['goalDays'] as int,
      );
      if (habit != null) {
        _habits.add(habit);
      }
    }
  }

  // Fallback to local habits if backend fails
  void _initializeDefaultHabitsLocal() {
    _habits = [
      Habit(id: 1, name: 'Prayer x5', goalDays: 30),
      Habit(id: 2, name: 'Morning food take Fruits', goalDays: 30),
      Habit(id: 3, name: 'Nuts & Dry Fruits (Limits)', goalDays: 30),
      Habit(id: 4, name: 'Running', goalDays: 30),
      Habit(id: 5, name: '10000+ Steps', goalDays: 30),
      Habit(id: 6, name: 'Chicken without Oil', goalDays: 30),
      Habit(id: 7, name: '11 PM Sleep', goalDays: 30),
      Habit(id: 8, name: 'Wake-up 7 AM', goalDays: 30),
      Habit(id: 9, name: 'Any Hard Workout', goalDays: 30),
      Habit(id: 10, name: 'No - Sugar', goalDays: 30),
      Habit(id: 11, name: 'No - Junk food / Fast Food', goalDays: 30),
      Habit(id: 12, name: 'No - Snacks', goalDays: 30),
      Habit(id: 13, name: 'No - M&M', goalDays: 26),
    ];
    _isInitialized = true;
  }

  // Reset when user logs out
  void reset() {
    _habits = [];
    _isInitialized = false;
    _layoutSettings = LayoutSettings.defaultSettings();
    notifyListeners();
  }

  // Layout Settings Methods
  void updateLayoutSettings(LayoutSettings settings) {
    _layoutSettings = settings;
    notifyListeners();
  }

  void toggleSectionVisibility(LayoutSection section) {
    final newVisibility = Map<LayoutSection, bool>.from(
      _layoutSettings.visibleSections,
    );
    newVisibility[section] = !(newVisibility[section] ?? true);
    _layoutSettings = _layoutSettings.copyWith(visibleSections: newVisibility);
    notifyListeners();
  }

  void reorderSections(int oldIndex, int newIndex) {
    final newOrder = List<LayoutSection>.from(_layoutSettings.sectionOrder);
    if (newIndex > oldIndex) newIndex--;
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    _layoutSettings = _layoutSettings.copyWith(sectionOrder: newOrder);
    notifyListeners();
  }

  void setDesktopColumns(int columns) {
    _layoutSettings = _layoutSettings.copyWith(columnsDesktop: columns);
    notifyListeners();
  }

  void setTabletColumns(int columns) {
    _layoutSettings = _layoutSettings.copyWith(columnsTablet: columns);
    notifyListeners();
  }

  void resetLayoutSettings() {
    _layoutSettings = LayoutSettings.defaultSettings();
    notifyListeners();
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

  Future<void> addHabit(String name, int goalDays) async {
    // Create on backend
    final habit = await _habitService.createHabit(name, goalDays);
    if (habit != null) {
      _habits.add(habit);
    } else {
      // Fallback to local
      final newId = _habits.isEmpty
          ? 1
          : _habits.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
      _habits.add(Habit(id: newId, name: name, goalDays: goalDays));
    }
    notifyListeners();
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
