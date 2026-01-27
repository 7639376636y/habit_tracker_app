import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class TopHabitsWidget extends StatelessWidget {
  const TopHabitsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final topHabits = provider.topHabits;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.yellow.shade700, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.yellow.shade700,
                child: const Center(
                  child: Text(
                    'TOP 10 DAILY HABITS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              ...topHabits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                return Container(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
}
