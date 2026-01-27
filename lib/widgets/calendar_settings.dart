import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class CalendarSettings extends StatelessWidget {
  const CalendarSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.green,
                child: const Center(
                  child: Text(
                    'CALENDAR SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    color: Colors.yellow[700],
                    child: const Text(
                      'YEAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: provider.selectedYear,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: List.generate(10, (index) => 2024 + index)
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) provider.setYear(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    color: Colors.yellow[700],
                    child: const Text(
                      'MONTH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: provider.selectedMonth,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('January')),
                          DropdownMenuItem(value: 2, child: Text('February')),
                          DropdownMenuItem(value: 3, child: Text('March')),
                          DropdownMenuItem(value: 4, child: Text('April')),
                          DropdownMenuItem(value: 5, child: Text('May')),
                          DropdownMenuItem(value: 6, child: Text('June')),
                          DropdownMenuItem(value: 7, child: Text('July')),
                          DropdownMenuItem(value: 8, child: Text('August')),
                          DropdownMenuItem(value: 9, child: Text('September')),
                          DropdownMenuItem(value: 10, child: Text('October')),
                          DropdownMenuItem(value: 11, child: Text('November')),
                          DropdownMenuItem(value: 12, child: Text('December')),
                        ],
                        onChanged: (value) {
                          if (value != null) provider.setMonth(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
