import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

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

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.purple,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text(
                        'OVERVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(weeks.length, (weekIndex) {
                          final week = weeks[weekIndex];
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getWeekColor(weekIndex),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'WEEK ${weekIndex + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: week.map((date) {
                                      return Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              _getDayName(date.weekday),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                              ),
                                            ),
                                            Text(
                                              '${date.day}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress rows
              Container(
                color: Colors.purple.shade50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildProgressRow(
                      'OVERALL PROGRESS',
                      weeks,
                      provider,
                      'header',
                    ),
                    const SizedBox(height: 4),
                    _buildProgressRow(
                      'COMPLETED',
                      weeks,
                      provider,
                      'completed',
                    ),
                    _buildProgressRow('GOAL', weeks, provider, 'goal'),
                    _buildProgressRow('LEFT', weeks, provider, 'left'),
                    const SizedBox(height: 4),
                    _buildProgressRow(
                      'WEEKLY PROGRESS',
                      weeks,
                      provider,
                      'percentage',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressRow(
    String label,
    List<List<DateTime>> weeks,
    HabitProvider provider,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: type == 'header' || type == 'percentage'
                ? Colors.purple.shade200
                : Colors.grey.shade200,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: type == 'header' || type == 'percentage'
                    ? Colors.purple.shade900
                    : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(weeks.length, (weekIndex) {
                final weekProgress = provider.weekProgress(weeks[weekIndex]);
                String value = '';
                Color? bgColor;

                switch (type) {
                  case 'header':
                    return const Expanded(child: SizedBox());
                  case 'completed':
                    value = '${weekProgress['completed']}';
                    break;
                  case 'goal':
                    value = '${weekProgress['goal']}';
                    break;
                  case 'left':
                    value = '${weekProgress['left']}';
                    break;
                  case 'percentage':
                    final pct = weekProgress['percentage'] as double;
                    value =
                        '${weekProgress['completed']}/${weekProgress['goal']}';
                    bgColor = Colors.green.withValues(alpha: pct / 100);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                }

                return Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: weeks[weekIndex].map((date) {
                      final dayValue = type == 'completed'
                          ? provider.completedOnDay(date)
                          : type == 'goal'
                          ? provider.habits.length
                          : provider.habits.length -
                                provider.completedOnDay(date);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          color: Colors.white,
                          child: Text(
                            '$dayValue',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
