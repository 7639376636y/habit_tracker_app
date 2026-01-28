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
  List<Habit> _archivedHabits = [];
  List<Habit> _pausedHabits = [];
  List<Habit> _trashHabits = [];
  LayoutSettings _layoutSettings = LayoutSettings.defaultSettings();
  bool _isLoading = false;
  bool _isInitialized = false;
  HabitLimits _limits = HabitLimits();

  HabitProvider();

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  List<Habit> get habits => _habits;
  List<Habit> get archivedHabits => _archivedHabits;
  List<Habit> get pausedHabits => _pausedHabits;
  List<Habit> get trashHabits => _trashHabits;
  LayoutSettings get layoutSettings => _layoutSettings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  HabitLimits get limits => _limits;

  // Get only active (non-paused) habits
  List<Habit> get activeHabits => _habits.where((h) => !h.isPaused).toList();

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
    _archivedHabits = [];
    _pausedHabits = [];
    _trashHabits = [];
    _isInitialized = false;
    _limits = HabitLimits();
    _layoutSettings = LayoutSettings.defaultSettings();
    notifyListeners();
  }

  // ========== Pause/Resume Methods ==========

  Future<void> pauseHabit(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    final updatedHabit = await _habitService.pauseHabit(habit.mongoId!);
    if (updatedHabit != null) {
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
      notifyListeners();
    }
  }

  Future<void> resumeHabit(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    final updatedHabit = await _habitService.resumeHabit(habit.mongoId!);
    if (updatedHabit != null) {
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
      notifyListeners();
    }
  }

  // ========== Archive Methods ==========

  Future<void> loadArchivedHabits() async {
    _archivedHabits = await _habitService.getArchivedHabits();
    notifyListeners();
  }

  Future<void> restoreArchivedHabit(int habitId) async {
    final habit = _archivedHabits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    final restoredHabit = await _habitService.restoreHabit(habit.mongoId!);
    if (restoredHabit != null) {
      _archivedHabits.removeWhere((h) => h.id == habitId);
      _habits.add(restoredHabit);
      notifyListeners();
    }
  }

  // ========== Trash Methods ==========

  Future<void> loadTrashHabits() async {
    _trashHabits = await _habitService.getTrashHabits();
    notifyListeners();
  }

  Future<void> restoreFromTrash(int habitId) async {
    final habit = _trashHabits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    final restoredHabit = await _habitService.restoreFromTrash(habit.mongoId!);
    if (restoredHabit != null) {
      _trashHabits.removeWhere((h) => h.id == habitId);
      _habits.add(restoredHabit);
      notifyListeners();
    }
  }

  Future<void> emptyTrash() async {
    await _habitService.emptyTrash();
    _trashHabits.clear();
    notifyListeners();
  }

  Future<void> permanentlyDelete(int habitId) async {
    final habit = _trashHabits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    final success = await _habitService.deleteHabit(
      habit.mongoId!,
      permanent: true,
    );
    if (success) {
      _trashHabits.removeWhere((h) => h.id == habitId);
      notifyListeners();
    }
  }

  // ========== Reminder Methods ==========

  Future<void> updateReminder(
    int habitId, {
    bool? enabled,
    String? time,
    List<int>? days,
  }) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    final updatedHabit = await _habitService.updateReminder(
      habit.mongoId!,
      enabled: enabled,
      time: time,
      days: days,
    );
    if (updatedHabit != null) {
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = updatedHabit;
        notifyListeners();
      }
    }
  }

  // ========== Duplicate Method ==========

  Future<Habit?> duplicateHabit(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return null;

    try {
      final duplicatedHabit = await _habitService.duplicateHabit(
        habit.mongoId!,
      );
      if (duplicatedHabit != null) {
        _habits.add(duplicatedHabit);
        notifyListeners();
        return duplicatedHabit;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // ========== Bulk Operations ==========

  Future<void> bulkArchive(List<int> habitIds) async {
    final mongoIds = _habits
        .where((h) => habitIds.contains(h.id) && h.mongoId != null)
        .map((h) => h.mongoId!)
        .toList();

    if (mongoIds.isEmpty) return;

    final count = await _habitService.bulkArchive(mongoIds);
    if (count > 0) {
      _habits.removeWhere((h) => habitIds.contains(h.id));
      notifyListeners();
      await loadArchivedHabits();
    }
  }

  Future<void> bulkDelete(List<int> habitIds) async {
    final mongoIds = _habits
        .where((h) => habitIds.contains(h.id) && h.mongoId != null)
        .map((h) => h.mongoId!)
        .toList();

    if (mongoIds.isEmpty) return;

    final count = await _habitService.bulkDelete(mongoIds);
    if (count > 0) {
      _habits.removeWhere((h) => habitIds.contains(h.id));
      notifyListeners();
    }
  }

  Future<void> bulkPause(List<int> habitIds) async {
    final mongoIds = _habits
        .where((h) => habitIds.contains(h.id) && h.mongoId != null)
        .map((h) => h.mongoId!)
        .toList();

    if (mongoIds.isEmpty) return;

    final count = await _habitService.bulkPause(mongoIds);
    if (count > 0) {
      await refreshHabits();
    }
  }

  Future<void> bulkResume(List<int> habitIds) async {
    final mongoIds = _habits
        .where((h) => habitIds.contains(h.id) && h.mongoId != null)
        .map((h) => h.mongoId!)
        .toList();

    if (mongoIds.isEmpty) return;

    final count = await _habitService.bulkResume(mongoIds);
    if (count > 0) {
      await refreshHabits();
    }
  }

  // ========== Stats Methods ==========

  Future<Map<String, dynamic>?> getStreakDetails(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return null;

    return await _habitService.getStreakDetails(habit.mongoId!);
  }

  Future<Map<String, dynamic>?> getAllStreaks() async {
    return await _habitService.getAllStreaks();
  }

  Future<Map<String, dynamic>?> getMonthlyStats() async {
    return await _habitService.getMonthlyStats(_selectedYear, _selectedMonth);
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
    if (habit.id == -1 || habit.mongoId == null) return;

    final success = await _habitService.archiveHabit(habit.mongoId!);
    if (success) {
      _habits.removeWhere((h) => h.id == habitId);
      // Add to archived list with updated status
      final archivedHabit = Habit(
        id: habit.id,
        mongoId: habit.mongoId,
        name: habit.name,
        goalDays: habit.goalDays,
        color: habit.color,
        icon: habit.icon,
        category: habit.category,
        completedDays: habit.completedDays,
        streak: habit.streak,
        isArchived: true,
        archivedAt: DateTime.now(),
      );
      _archivedHabits.add(archivedHabit);
      notifyListeners();
    }
  }

  /// Soft delete - moves habit to trash (can be restored within 30 days)
  Future<void> removeHabit(int habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: '', goalDays: 0),
    );
    if (habit.id == -1 || habit.mongoId == null) return;

    // Delete from backend (soft delete - moves to trash)
    final success = await _habitService.deleteHabit(habit.mongoId!);
    if (success) {
      _habits.removeWhere((h) => h.id == habitId);
      // Add to trash list with updated status
      final trashedHabit = Habit(
        id: habit.id,
        mongoId: habit.mongoId,
        name: habit.name,
        goalDays: habit.goalDays,
        color: habit.color,
        icon: habit.icon,
        category: habit.category,
        completedDays: habit.completedDays,
        streak: habit.streak,
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      _trashHabits.add(trashedHabit);
      notifyListeners();
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
