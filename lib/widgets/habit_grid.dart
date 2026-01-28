import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import 'habit_actions_sheet.dart';

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
                          context,
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
    BuildContext context,
    HabitProvider provider,
    dynamic habit,
    int index,
    List<List<DateTime>> weeks,
    double indexWidth,
    double habitNameWidth,
    double goalWidth,
    double dayWidth,
  ) {
    final isPaused = habit is Habit && habit.isPaused;

    return GestureDetector(
      onLongPress: () {
        if (habit is Habit) {
          showHabitActionsSheet(context, habit);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isPaused
              ? const Color(0xFFFEF3C7).withValues(alpha: 0.5)
              : (index.isEven ? Colors.white : const Color(0xFFFAFAFA)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPaused
                ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9),
          ),
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
                    color: isPaused
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                        : const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: isPaused
                        ? const Icon(
                            Icons.pause_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          )
                        : Text(
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
            // Name (clickable to show actions)
            SizedBox(
              width: habitNameWidth,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (habit is Habit) {
                      showHabitActionsSheet(context, habit);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isPaused
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF1F2937),
                              fontStyle: isPaused
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPaused)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Paused',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Goal
            SizedBox(
              width: goalWidth,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1,
                              ),
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
    return _MobileHabitsSection(
      provider: provider,
      habits: habits,
      weeks: weeks,
      getWeekColor: _getWeekColor,
      isToday: _isToday,
      getDayName: _getDayName,
      buildEmptyState: _buildEmptyState,
    );
  }
}

class _MobileHabitsSection extends StatefulWidget {
  final HabitProvider provider;
  final List habits;
  final List<List<DateTime>> weeks;
  final Color Function(int) getWeekColor;
  final bool Function(DateTime) isToday;
  final String Function(int) getDayName;
  final Widget Function() buildEmptyState;

  const _MobileHabitsSection({
    required this.provider,
    required this.habits,
    required this.weeks,
    required this.getWeekColor,
    required this.isToday,
    required this.getDayName,
    required this.buildEmptyState,
  });

  @override
  State<_MobileHabitsSection> createState() => _MobileHabitsSectionState();
}

class _MobileHabitsSectionState extends State<_MobileHabitsSection> {
  late int _selectedWeekIndex;

  @override
  void initState() {
    super.initState();
    _selectedWeekIndex = _findCurrentWeekIndex();
  }

  int _findCurrentWeekIndex() {
    final now = DateTime.now();
    for (int i = 0; i < widget.weeks.length; i++) {
      for (final date in widget.weeks[i]) {
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          return i;
        }
      }
    }
    return 0;
  }

  void _onWeekChanged(int index) {
    setState(() {
      _selectedWeekIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Header with week selector
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
            child: Column(
              children: [
                Row(
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
                    const Expanded(
                      child: Text(
                        'Daily Habits',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Go to today button
                    GestureDetector(
                      onTap: () {
                        final todayIndex = _findCurrentWeekIndex();
                        _onWeekChanged(todayIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.today_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Global week selector
                Row(
                  children: [
                    // Previous week
                    GestureDetector(
                      onTap: _selectedWeekIndex > 0
                          ? () => _onWeekChanged(_selectedWeekIndex - 1)
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: _selectedWeekIndex > 0 ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white.withValues(
                            alpha: _selectedWeekIndex > 0 ? 1.0 : 0.4,
                          ),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Week tabs
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.weeks.length, (index) {
                            final isSelected = index == _selectedWeekIndex;
                            final isCurrentWeek =
                                index == _findCurrentWeekIndex();
                            return GestureDetector(
                              onTap: () => _onWeekChanged(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isCurrentWeek && !isSelected
                                      ? Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'W${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : Colors.white,
                                      ),
                                    ),
                                    if (isCurrentWeek) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFBBF24)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Next week
                    GestureDetector(
                      onTap: _selectedWeekIndex < widget.weeks.length - 1
                          ? () => _onWeekChanged(_selectedWeekIndex + 1)
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: _selectedWeekIndex < widget.weeks.length - 1
                                ? 0.2
                                : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(
                            alpha: _selectedWeekIndex < widget.weeks.length - 1
                                ? 1.0
                                : 0.4,
                          ),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Habits List
          if (widget.habits.isEmpty)
            widget.buildEmptyState()
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...widget.habits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final habit = entry.value;
                    return _MobileHabitCard(
                      provider: widget.provider,
                      habit: habit,
                      index: index,
                      weeks: widget.weeks,
                      selectedWeekIndex: _selectedWeekIndex,
                      getWeekColor: widget.getWeekColor,
                      isToday: widget.isToday,
                      getDayName: widget.getDayName,
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileHabitCard extends StatelessWidget {
  final HabitProvider provider;
  final dynamic habit;
  final int index;
  final List<List<DateTime>> weeks;
  final int selectedWeekIndex;
  final Color Function(int) getWeekColor;
  final bool Function(DateTime) isToday;
  final String Function(int) getDayName;

  const _MobileHabitCard({
    required this.provider,
    required this.habit,
    required this.index,
    required this.weeks,
    required this.selectedWeekIndex,
    required this.getWeekColor,
    required this.isToday,
    required this.getDayName,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = habit.completedCount;
    final goalDays = habit.goalDays;
    final progress = goalDays > 0
        ? (completedCount / goalDays).clamp(0.0, 1.0)
        : 0.0;
    final habitColor = getWeekColor(index);
    final isPaused = habit is Habit && habit.isPaused;

    return GestureDetector(
      onTap: () {
        if (habit is Habit) {
          showHabitActionsSheet(context, habit);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isPaused ? const Color(0xFFFEF3C7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPaused
              ? Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: habitColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient accent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    habitColor.withValues(alpha: 0.08),
                    habitColor.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Habit index badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [habitColor, habitColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: habitColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Habit name and stats (clickable to show actions)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (habit is Habit) {
                          showHabitActionsSheet(context, habit);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isPaused
                                        ? const Color(0xFF92400E)
                                        : const Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                    fontStyle: isPaused
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPaused)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pause_circle_filled_rounded,
                                        size: 12,
                                        color: Color(0xFFD97706),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Paused',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatChip(
                                icon: Icons.flag_rounded,
                                label: '$goalDays',
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                icon: Icons.check_circle_rounded,
                                label: '$completedCount',
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                icon: Icons.percent_rounded,
                                label: '${(progress * 100).toInt()}%',
                                color: progress >= 1.0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0
                                  ? const Color(0xFF10B981)
                                  : habitColor,
                            ),
                          ),
                        ),
                        if (progress >= 1.0)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Text(
                            '$completedCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: habitColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Single week display using selectedWeekIndex
            _buildWeekContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekContent() {
    final week = weeks[selectedWeekIndex];
    final weekColor = getWeekColor(selectedWeekIndex);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: weekColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: weekColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            // Week header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [weekColor, weekColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: weekColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Week ${selectedWeekIndex + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: weekColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${week.where((d) => habit.isCompletedOn(d)).length}/${week.length} days',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: weekColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Day cells
            SizedBox(
              height: 64,
              child: Row(
                children: week.map((date) {
                  final isCompleted = habit.isCompletedOn(date);
                  final isTodayDate = isToday(date);
                  final isFuture = date.isAfter(DateTime.now());

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => provider.toggleHabitDay(habit.id, date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                  )
                                : null,
                            color: isCompleted
                                ? null
                                : isTodayDate
                                ? const Color(0xFFFEF3C7)
                                : isFuture
                                ? const Color(0xFFF8FAFC)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTodayDate
                                  ? const Color(0xFFFBBF24)
                                  : isCompleted
                                  ? Colors.transparent
                                  : const Color(0xFFE2E8F0),
                              width: isTodayDate ? 2 : 1,
                            ),
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : isTodayDate
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFBBF24,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getDayName(date.weekday).substring(0, 3),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isCompleted)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isTodayDate
                                        ? const Color(0xFFD97706)
                                        : isFuture
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
