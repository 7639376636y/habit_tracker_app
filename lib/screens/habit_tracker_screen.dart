import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/calendar_settings.dart';
import '../widgets/overview_section.dart';
import '../widgets/habit_grid.dart';
import '../widgets/progress_chart.dart';
import '../widgets/monthly_progress_pie.dart';
import '../widgets/top_habits_widget.dart';
import '../widgets/overall_progress_widget.dart';

class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with header, chart, and monthly progress
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column: Title and Calendar Settings
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'HABIT TRACKER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '- ${provider.monthName} -',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Calendar Settings
                          const CalendarSettings(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Center: Progress Chart
                    Expanded(child: Column(children: [const ProgressChart()])),
                    const SizedBox(width: 16),
                    // Right column: Monthly Progress Pie
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          const MonthlyProgressPie(),
                          const SizedBox(height: 16),
                          const TopHabitsWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Overview Section
                const OverviewSection(),
                const SizedBox(height: 16),
                // Bottom row: Habit Grid and Overall Progress
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Habit Grid
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: const HabitGrid(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Overall Progress
                    const SizedBox(width: 250, child: OverallProgressWidget()),
                  ],
                ),
                const SizedBox(height: 16),
                // Add Habit Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddHabitDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Habit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, HabitProvider provider) {
    final nameController = TextEditingController();
    final goalController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(
                labelText: 'Goal (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final goal = int.tryParse(goalController.text) ?? 30;
              if (name.isNotEmpty) {
                provider.addHabit(name, goal);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
