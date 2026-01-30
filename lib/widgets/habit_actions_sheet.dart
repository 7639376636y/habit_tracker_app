import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../main.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'add_habit_dialog.dart';

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
  return const Color(0xFF6366F1); // Default indigo
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

class HabitActionsSheet extends StatelessWidget {
  final Habit habit;

  const HabitActionsSheet({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Habit header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 30,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildStatusBadge(),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 14,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${habit.streak} day streak',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            // Action buttons
            _buildActionTile(
              context,
              icon: Icons.edit_rounded,
              label: 'Edit Habit',
              color: const Color(0xFF3B82F6),
              onTap: () => _editHabit(context),
            ),
            if (!habit.isPaused)
              _buildActionTile(
                context,
                icon: Icons.pause_circle_outline_rounded,
                label: 'Pause Habit',
                subtitle: 'Temporarily stop tracking this habit',
                color: const Color(0xFFF59E0B),
                onTap: () => _pauseHabit(context),
              )
            else
              _buildActionTile(
                context,
                icon: Icons.play_circle_outline_rounded,
                label: 'Resume Habit',
                subtitle: 'Continue tracking this habit',
                color: const Color(0xFF10B981),
                onTap: () => _resumeHabit(context),
              ),
            _buildActionTile(
              context,
              icon: Icons.copy_rounded,
              label: 'Duplicate Habit',
              subtitle: 'Create a copy of this habit',
              color: const Color(0xFF8B5CF6),
              onTap: () => _duplicateHabit(context),
            ),
            _buildActionTile(
              context,
              icon: Icons.notifications_outlined,
              label: 'Set Reminder',
              subtitle: habit.reminder.enabled
                  ? 'Reminder at ${habit.reminder.time}'
                  : 'No reminder set',
              color: const Color(0xFF6366F1),
              onTap: () => _setReminder(context),
            ),
            _buildActionTile(
              context,
              icon: Icons.archive_outlined,
              label: 'Archive Habit',
              subtitle: 'Hide from main view but keep data',
              color: const Color(0xFF64748B),
              onTap: () => _archiveHabit(context),
            ),
            _buildActionTile(
              context,
              icon: Icons.delete_outline_rounded,
              label: 'Delete Habit',
              subtitle: 'Move to trash (30 days recovery)',
              color: const Color(0xFFEF4444),
              onTap: () => _deleteHabit(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (habit.isPaused) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_filled_rounded,
              size: 14,
              color: Color(0xFFF59E0B),
            ),
            SizedBox(width: 4),
            Text(
              'Paused',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
          SizedBox(width: 4),
          Text(
            'Active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color == const Color(0xFFEF4444)
                          ? color
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _editHabit(BuildContext context) {
    Navigator.pop(context);
    // Use the same dialog as Add Habit, but in edit mode
    showAddHabitDialog(context, editHabit: habit);
  }

  Future<void> _pauseHabit(BuildContext context) async {
    Navigator.pop(context);
    await context.read<HabitProvider>().pauseHabit(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} paused'),
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resumeHabit(BuildContext context) async {
    Navigator.pop(context);
    await context.read<HabitProvider>().resumeHabit(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} resumed'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _duplicateHabit(BuildContext context) async {
    Navigator.pop(context);
    try {
      final duplicated = await context.read<HabitProvider>().duplicateHabit(
        habit.id,
      );
      if (context.mounted && duplicated != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${duplicated.name} created'),
            backgroundColor: const Color(0xFF8B5CF6),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _setReminder(BuildContext context) {
    Navigator.pop(context);
    _showReminderDialog(context);
  }

  void _showReminderDialog(BuildContext context) {
    final isEnabled = habit.reminder.enabled;
    TimeOfDay selectedTime = TimeOfDay.now();

    if (habit.reminder.time.isNotEmpty) {
      final parts = habit.reminder.time.split(':');
      if (parts.length >= 2) {
        selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Reminder',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Get notified to complete your habit',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Time picker
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap to change',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEnabled) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          context.read<HabitProvider>().updateReminder(
                            habit.id,
                            enabled: false,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reminder disabled'),
                              backgroundColor: Color(0xFF64748B),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        child: const Text(
                          'Disable',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final timeStr =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                          context.read<HabitProvider>().updateReminder(
                            habit.id,
                            enabled: true,
                            time: timeStr,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reminder set for ${selectedTime.format(context)}',
                              ),
                              backgroundColor: const Color(0xFF6366F1),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Reminder',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _archiveHabit(BuildContext context) async {
    Navigator.pop(context);
    await context.read<HabitProvider>().archiveHabit(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} archived'),
          backgroundColor: const Color(0xFF64748B),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteHabit(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    final habitName = habit.name;
    final habitId = habit.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Delete Habit?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$habitName"? It will be moved to trash and can be restored within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Pop the bottom sheet first
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Perform delete
      await provider.removeHabit(habitId);

      // Show snackbar with undo action, but auto-dismiss after 3 seconds
      ScaffoldMessengerState? messengerState =
          rootScaffoldMessengerKey.currentState;
      if (messengerState != null) {
        messengerState.showSnackBar(
          SnackBar(
            content: Text('$habitName deleted'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(
              seconds: 10,
            ), // Set longer to ensure action is clickable
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                provider.restoreFromTrash(habitId);
              },
            ),
          ),
        );

        // Auto-dismiss after 3 seconds if not already dismissed
        Future.delayed(const Duration(seconds: 3), () {
          rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        });
      }
    }
  }
}

// Helper function to show the actions sheet
void showHabitActionsSheet(BuildContext context, Habit habit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HabitActionsSheet(habit: habit),
  );
}
