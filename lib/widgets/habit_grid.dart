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
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
    ];
    return colors[weekIndex % colors.length];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final weeks = provider.weeksInMonth;
        final habits = provider.habits;

        if (isMobile) {
          return _buildMobileLayout(context, provider, habits, weeks);
        }

        return _buildDesktopLayout(context, provider, habits, weeks);
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    HabitProvider provider,
    List habits,
    List<List<DateTime>> weeks,
  ) {
    // Calculate total days in month
    final totalDays = weeks.fold<int>(0, (sum, week) => sum + week.length);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Habit Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Responsive Table
          if (habits.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth - 32; // padding
                final indexWidth = 32.0;
                final goalWidth = 40.0;
                final habitNameWidth = availableWidth * 0.15; // 15% for name
                // Account for week gaps: 2px gap between each week, plus 8px padding per week
                final weekGaps = (weeks.length - 1) * 2.0;
                final weekPadding = weeks.length * 8.0;
                final daysWidth =
                    availableWidth -
                    indexWidth -
                    goalWidth -
                    habitNameWidth -
                    16 -
                    weekGaps -
                    weekPadding;
                final dayWidth = daysWidth / totalDays;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Header
                      _buildFlexibleTableHeader(
                        weeks,
                        indexWidth,
                        habitNameWidth,
                        goalWidth,
                        dayWidth,
                      ),
                      const SizedBox(height: 8),
                      // Table Body
                      ...habits.asMap().entries.map((entry) {
                        final index = entry.key;
                        final habit = entry.value;
                        return _buildFlexibleHabitRow(
                          provider,
                          habit,
                          index,
                          weeks,
                          indexWidth,
                          habitNameWidth,
                          goalWidth,
                          dayWidth,
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFlexibleTableHeader(
    List<List<DateTime>> weeks,
    double indexWidth,
    double habitNameWidth,
    double goalWidth,
    double dayWidth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: indexWidth,
            child: const Center(
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          SizedBox(
            width: habitNameWidth,
            child: const Text(
              'Habit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(
            width: goalWidth,
            child: const Center(
              child: Text(
                'Goal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: weeks.asMap().entries.map((weekEntry) {
                final weekIndex = weekEntry.key;
                final week = weekEntry.value;
                final weekColor = _getWeekColor(weekIndex);
                return Expanded(
                  flex: week.length,
                  child: Container(
                    margin: EdgeInsets.only(left: weekIndex > 0 ? 2 : 0),
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 2,
                    ),
                    decoration: BoxDecoration(
                      color: weekColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: weekColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'W${weekIndex + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: weekColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: week.map((date) {
                            final isToday = _isToday(date);
                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _getDayName(date.weekday).substring(0, 1),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 1),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? const Color(0xFFFBBF24)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isToday
                                            ? Colors.black
                                            : const Color(0xFF64748B),
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
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexibleHabitRow(
    HabitProvider provider,
    dynamic habit,
    int index,
    List<List<DateTime>> weeks,
    double indexWidth,
    double habitNameWidth,
    double goalWidth,
    double dayWidth,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: indexWidth,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Name
          SizedBox(
            width: habitNameWidth,
            child: Text(
              habit.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Goal
          SizedBox(
            width: goalWidth,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${habit.goalDays}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ),
          ),
          // Day checkboxes grouped by week
          Expanded(
            child: Row(
              children: weeks.asMap().entries.map((weekEntry) {
                final weekIndex = weekEntry.key;
                final week = weekEntry.value;
                final weekColor = _getWeekColor(weekIndex);
                return Expanded(
                  flex: week.length,
                  child: Container(
                    margin: EdgeInsets.only(left: weekIndex > 0 ? 2 : 0),
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 2,
                    ),
                    decoration: BoxDecoration(
                      color: weekColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: week.map((date) {
                        final isCompleted = habit.isCompletedOn(date);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    provider.toggleHabitDay(habit.id, date),
                                borderRadius: BorderRadius.circular(6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: isCompleted
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF10B981),
                                              Color(0xFF059669),
                                            ],
                                          )
                                        : null,
                                    color: isCompleted
                                        ? null
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: isCompleted
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_task_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No habits added yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    HabitProvider provider,
    List habits,
    List<List<DateTime>> weeks,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Daily Habits',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Habits List
          if (habits.isEmpty)
            _buildEmptyState()
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...habits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final habit = entry.value;
                    return _buildMobileHabitCard(provider, habit, index, weeks);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileHabitCard(
    HabitProvider provider,
    dynamic habit,
    int index,
    List<List<DateTime>> weeks,
  ) {
    // Calculate total days
    final totalDays = weeks.fold<int>(0, (sum, week) => sum + week.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit Info
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getWeekColor(index),
                      _getWeekColor(index).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Goal: ${habit.goalDays} • Done: ${habit.completedCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // All days grouped by week
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final weekGaps = (weeks.length - 1) * 4.0;
              final daysWidth = availableWidth - weekGaps;
              final dayWidth = daysWidth / totalDays;

              return Row(
                children: weeks.asMap().entries.map((weekEntry) {
                  final weekIndex = weekEntry.key;
                  final week = weekEntry.value;
                  final weekColor = _getWeekColor(weekIndex);
                  return Container(
                    width:
                        week.length * dayWidth +
                        (weekIndex < weeks.length - 1 ? 4 : 0),
                    padding: EdgeInsets.only(
                      right: weekIndex < weeks.length - 1 ? 4 : 0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: weekColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: weekColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'W${weekIndex + 1}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: weekColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: week.map((date) {
                              final isCompleted = habit.isCompletedOn(date);
                              final isToday = _isToday(date);
                              return SizedBox(
                                width: dayWidth,
                                child: GestureDetector(
                                  onTap: () =>
                                      provider.toggleHabitDay(habit.id, date),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    height: 28,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isCompleted
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF10B981),
                                                Color(0xFF059669),
                                              ],
                                            )
                                          : null,
                                      color: isCompleted
                                          ? null
                                          : isToday
                                          ? const Color(0xFFFEF3C7)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isToday
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFFE5E7EB),
                                        width: isToday ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (dayWidth > 18)
                                          Text(
                                            '${date.day}',
                                            style: TextStyle(
                                              fontSize: dayWidth > 25 ? 9 : 7,
                                              fontWeight: FontWeight.w600,
                                              color: isCompleted
                                                  ? Colors.white
                                                  : isToday
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF1F2937),
                                            ),
                                          )
                                        else if (isCompleted)
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
