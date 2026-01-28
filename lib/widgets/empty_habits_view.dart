import 'package:flutter/material.dart';

class EmptyHabitsView extends StatelessWidget {
  final VoidCallback onAddHabit;

  const EmptyHabitsView({super.key, required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circles
                  Positioned(
                    top: 30,
                    left: 20,
                    child: _buildFloatingIcon(
                      Icons.fitness_center,
                      const Color(0xFF10B981),
                      24,
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 25,
                    child: _buildFloatingIcon(
                      Icons.self_improvement,
                      const Color(0xFFF59E0B),
                      20,
                    ),
                  ),
                  Positioned(
                    bottom: 45,
                    left: 30,
                    child: _buildFloatingIcon(
                      Icons.menu_book,
                      const Color(0xFF3B82F6),
                      22,
                    ),
                  ),
                  Positioned(
                    bottom: 35,
                    right: 35,
                    child: _buildFloatingIcon(
                      Icons.bedtime,
                      const Color(0xFFEC4899),
                      18,
                    ),
                  ),
                  // Main icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Title
            const Text(
              'Start Your Journey',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Build better habits, one day at a time.\nCreate your first habit to begin tracking your progress.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Add Habit Button
            FilledButton.icon(
              onPressed: onAddHabit,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Your First Habit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),

            // Tips section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tips for success',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTip('Start small - choose 1-3 habits to focus on'),
                  const SizedBox(height: 8),
                  _buildTip('Be specific - "Exercise 30 min" vs "Exercise"'),
                  const SizedBox(height: 8),
                  _buildTip('Track daily for at least 21 days'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, double size) {
    return Container(
      padding: EdgeInsets.all(size / 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
