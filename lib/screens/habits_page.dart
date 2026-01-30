import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_grid.dart';
import '../widgets/empty_habits_view.dart';
import '../widgets/add_habit_dialog.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'My Habits',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: provider.isLoading
                        ? null
                        : () async {
                            await provider.refreshHabits();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Habits synced'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.sync,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.refreshHabits(),
            child: provider.isLoading && !provider.isInitialized
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : provider.hasHabits
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: const HabitGrid(),
                  )
                : EmptyHabitsView(
                    onAddHabit: () => showAddHabitDialog(context),
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddHabitDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Habit'),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
