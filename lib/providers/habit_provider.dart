import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  int _selectedYear = 2026;
  int _selectedMonth = 1; // January
  List<Habit> _habits = [];

  HabitProvider() {
    _initializeDefaultHabits();
  }

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  List<Habit> get habits => _habits;

  void _initializeDefaultHabits() {
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
  }

  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void toggleHabitDay(int habitId, DateTime date) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _habits[index] = _habits[index].toggleDay(date);
      notifyListeners();
    }
  }

  void addHabit(String name, int goalDays) {
    final newId = _habits.isEmpty
        ? 1
        : _habits.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
    _habits.add(Habit(id: newId, name: name, goalDays: goalDays));
    notifyListeners();
  }

  void removeHabit(int habitId) {
    _habits.removeWhere((h) => h.id == habitId);
    notifyListeners();
  }

  void updateHabit(int habitId, String name, int goalDays) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(name: name, goalDays: goalDays);
      notifyListeners();
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
