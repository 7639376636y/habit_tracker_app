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

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadTrashHabits();
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
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Trash',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<HabitProvider>(
            builder: (context, provider, _) {
              if (provider.trashHabits.isEmpty) return const SizedBox();
              return TextButton.icon(
                onPressed: () => _confirmEmptyTrash(context, provider),
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFEF4444),
                ),
                label: const Text(
                  'Empty Trash',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final trashHabits = provider.trashHabits;

          if (trashHabits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 64,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Trash is Empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deleted habits will appear here for 30 days',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trashHabits.length,
            itemBuilder: (context, index) {
              final habit = trashHabits[index];
              return _buildTrashHabitCard(context, habit, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrashHabitCard(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) {
    final daysRemaining = habit.deletedAt != null
        ? 30 - DateTime.now().difference(habit.deletedAt!).inDays
        : 30;

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
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: daysRemaining <= 7
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      daysRemaining > 0
                          ? '$daysRemaining days until permanent deletion'
                          : 'Will be deleted soon',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysRemaining <= 7
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Restore button
              IconButton(
                onPressed: () => _restoreHabit(context, habit, provider),
                tooltip: 'Restore',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restore_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
              ),
              // Permanent delete button
              IconButton(
                onPressed: () =>
                    _confirmPermanentDelete(context, habit, provider),
                tooltip: 'Delete permanently',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
              ),
            ],
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
    await provider.restoreFromTrash(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} restored'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _confirmPermanentDelete(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Delete Permanently?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${habit.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.permanentlyDelete(habit.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.name} permanently deleted'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    HabitProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Empty Trash?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete all habits in trash? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.emptyTrash();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trash emptied'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
