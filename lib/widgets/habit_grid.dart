import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class HabitGrid extends StatelessWidget {
  const HabitGrid({super.key});

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Color _getWeekColor(int weekIndex) {
    const colors = [
      Color(0xFF9C27B0), // Purple
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFFF9800), // Orange
      Color(0xFFF44336), // Red
      Color(0xFF607D8B), // Blue Grey
    ];
    return colors[weekIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final weeks = provider.weeksInMonth;
        final habits = provider.habits;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                color: Colors.blue.shade100,
                child: Row(
                  children: [
                    // Habit name and goals columns
                    Container(
                      width: 50,
                      padding: const EdgeInsets.all(4),
                      child: const SizedBox(),
                    ),
                    Container(
                      width: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        border: Border.all(color: Colors.blue.shade900),
                      ),
                      child: const Text(
                        'DAILY HABITS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        border: Border.all(color: Colors.green.shade900),
                      ),
                      child: const Text(
                        'GOALS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Week columns
                    ...List.generate(weeks.length, (weekIndex) {
                      final week = weeks[weekIndex];
                      return Container(
                        width: week.length * 32.0,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getWeekColor(weekIndex),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                'WEEK ${weekIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Row(
                              children: week.map((date) {
                                return SizedBox(
                                  width: 32,
                                  child: Column(
                                    children: [
                                      Text(
                                        _getDayName(date.weekday),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.all(2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isToday(date)
                                              ? Colors.yellow
                                              : Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        child: Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _isToday(date)
                                                ? Colors.black
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Habit rows
              ...habits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                return Container(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  child: Row(
                    children: [
                      // Row number
                      Container(
                        width: 50,
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Habit name
                      Container(
                        width: 180,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          habit.name,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Goal
                      Container(
                        width: 60,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${habit.goalDays}',
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Checkboxes for each week
                      ...List.generate(weeks.length, (weekIndex) {
                        final week = weeks[weekIndex];
                        return SizedBox(
                          width: week.length * 32.0,
                          child: Row(
                            children: week.map((date) {
                              final isCompleted = habit.isCompletedOn(date);
                              return SizedBox(
                                width: 32,
                                height: 28,
                                child: InkWell(
                                  onTap: () {
                                    provider.toggleHabitDay(habit.id, date);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      color: isCompleted
                                          ? Colors.blue.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.blue,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
