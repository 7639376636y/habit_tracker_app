import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

/// Helper function to parse color from string
Color _parseColor(String colorStr) {
  if (colorStr.startsWith('#')) {
    final hex = colorStr.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }
  return const Color(0xFF6366F1);
}

/// Map icon string names to IconData
IconData _parseIcon(String iconName) {
  const iconMap = <String, IconData>{
    'check_circle': Icons.check_circle_outline_rounded,
    'fitness': Icons.fitness_center_rounded,
    'book': Icons.book_rounded,
    'water': Icons.water_drop_rounded,
    'sleep': Icons.bedtime_rounded,
    'meditation': Icons.self_improvement_rounded,
    'run': Icons.directions_run_rounded,
    'walk': Icons.directions_walk_rounded,
    'food': Icons.restaurant_rounded,
    'study': Icons.school_rounded,
    'code': Icons.code_rounded,
    'music': Icons.music_note_rounded,
    'money': Icons.attach_money_rounded,
    'heart': Icons.favorite_rounded,
  };
  return iconMap[iconName] ?? Icons.check_circle_outline_rounded;
}

class ArchivedScreen extends StatefulWidget {
  const ArchivedScreen({super.key});

  @override
  State<ArchivedScreen> createState() => _ArchivedScreenState();
}

class _ArchivedScreenState extends State<ArchivedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadArchivedHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 12),
            Text(
              'Archived Habits',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final archivedHabits = provider.archivedHabits;

          if (archivedHabits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.archive_outlined,
                      size: 64,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Archived Habits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Archived habits will appear here',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archivedHabits.length,
            itemBuilder: (context, index) {
              final habit = archivedHabits[index];
              return _buildArchivedHabitCard(context, habit, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildArchivedHabitCard(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) {
    final archivedDate = habit.archivedAt != null
        ? '${habit.archivedAt!.day}/${habit.archivedAt!.month}/${habit.archivedAt!.year}'
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Habit Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _parseColor(habit.color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _parseIcon(habit.icon),
              color: _parseColor(habit.color),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Habit Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.archive_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Archived on $archivedDate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${habit.streak} day streak',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Restore button
          IconButton(
            onPressed: () => _restoreHabit(context, habit, provider),
            tooltip: 'Restore',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.unarchive_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreHabit(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) async {
    await provider.restoreArchivedHabit(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} restored'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}
