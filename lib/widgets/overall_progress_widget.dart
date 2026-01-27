import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class OverallProgressWidget extends StatelessWidget {
  const OverallProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final habits = provider.habits;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.blue.shade700,
                child: const Center(
                  child: Text(
                    'OVERALL PROGRESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Header row
              Container(
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: const Row(
                  children: [
                    SizedBox(width: 30),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'LEFT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Habit progress rows
              ...habits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                final percentage = habit.progressPercentage;

                return Container(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${habit.completedCount}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${habit.leftCount}',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Row(
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: percentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
