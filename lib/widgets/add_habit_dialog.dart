import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

/// Available colors for habits
const List<Color> habitColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Purple
  Color(0xFF10B981), // Green
  Color(0xFFF59E0B), // Amber
  Color(0xFFEF4444), // Red
  Color(0xFF3B82F6), // Blue
  Color(0xFFEC4899), // Pink
  Color(0xFF14B8A6), // Teal
  Color(0xFFF97316), // Orange
  Color(0xFF8B5CF6), // Violet
];

/// Available icons for habits
const List<IconData> habitIcons = [
  Icons.check_circle_outline_rounded,
  Icons.fitness_center_rounded,
  Icons.book_rounded,
  Icons.water_drop_rounded,
  Icons.bedtime_rounded,
  Icons.self_improvement_rounded,
  Icons.directions_run_rounded,
  Icons.restaurant_rounded,
  Icons.school_rounded,
  Icons.code_rounded,
  Icons.music_note_rounded,
  Icons.attach_money_rounded,
  Icons.favorite_rounded,
  Icons.brush_rounded,
  Icons.coffee_rounded,
  Icons.local_pharmacy_rounded,
];

/// Map IconData to string name for backend
String iconToString(IconData icon) {
  final iconMap = <IconData, String>{
    Icons.check_circle_outline_rounded: 'check_circle',
    Icons.fitness_center_rounded: 'fitness',
    Icons.book_rounded: 'book',
    Icons.water_drop_rounded: 'water',
    Icons.bedtime_rounded: 'sleep',
    Icons.self_improvement_rounded: 'meditation',
    Icons.directions_run_rounded: 'run',
    Icons.restaurant_rounded: 'food',
    Icons.school_rounded: 'study',
    Icons.code_rounded: 'code',
    Icons.music_note_rounded: 'music',
    Icons.attach_money_rounded: 'money',
    Icons.favorite_rounded: 'heart',
    Icons.brush_rounded: 'art',
    Icons.coffee_rounded: 'coffee',
    Icons.local_pharmacy_rounded: 'health',
  };
  return iconMap[icon] ?? 'check_circle';
}

/// Map color to hex string for backend
String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

class AddHabitDialog extends StatefulWidget {
  final Habit? editHabit; // If provided, we're editing

  const AddHabitDialog({super.key, this.editHabit});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _descriptionController;

  Color _selectedColor = habitColors[0];
  IconData _selectedIcon = habitIcons[0];
  HabitCategory _selectedCategory = HabitCategory.other;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  bool get isEditing => widget.editHabit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editHabit?.name ?? '');
    _goalController = TextEditingController(
      text: widget.editHabit?.goalDays.toString() ?? '30',
    );
    _descriptionController = TextEditingController(
      text: widget.editHabit?.description ?? '',
    );

    if (widget.editHabit != null) {
      _selectedCategory = widget.editHabit!.category;
      _reminderEnabled = widget.editHabit!.reminder.enabled;
      if (widget.editHabit!.reminder.time.isNotEmpty) {
        final parts = widget.editHabit!.reminder.time.split(':');
        if (parts.length >= 2) {
          _reminderTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _selectedColor,
                        _selectedColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_selectedIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Habit' : 'Add New Habit',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEditing
                            ? 'Update your habit details'
                            : 'Start building a better you',
                        style: const TextStyle(
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

            // Habit Name
            _buildLabel('Habit Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g., Exercise, Read, Meditate',
              icon: Icons.edit_rounded,
            ),
            const SizedBox(height: 16),

            // Description (optional)
            _buildLabel('Description (optional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hint: 'What is this habit about?',
              icon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Goal Days
            _buildLabel('Goal (days per month)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _goalController,
              hint: 'Number of days',
              icon: Icons.flag_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Category
            _buildLabel('Category'),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 20),

            // Color Selection
            _buildLabel('Color'),
            const SizedBox(height: 8),
            _buildColorSelector(),
            const SizedBox(height: 20),

            // Icon Selection
            _buildLabel('Icon'),
            const SizedBox(height: 8),
            _buildIconSelector(),
            const SizedBox(height: 20),

            // Reminder
            _buildReminderSection(),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _selectedColor,
                          _selectedColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveHabit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Create Habit',
                        style: const TextStyle(
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HabitCategory.values.map((category) {
        final isSelected = category == _selectedCategory;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _selectedColor : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              category.name[0].toUpperCase() + category.name.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: habitColors.map((color) {
        final isSelected = color == _selectedColor;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconSelector() {
    return SizedBox(
      height: 100,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: habitIcons.length,
        itemBuilder: (context, index) {
          final icon = habitIcons[index];
          final isSelected = icon == _selectedIcon;
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = icon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_rounded,
                color: _selectedColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Daily Reminder',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
                activeThumbColor: _selectedColor,
              ),
            ],
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: _selectedColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _reminderTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tap to change',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() => _reminderTime = time);
    }
  }

  void _saveHabit() {
    final name = _nameController.text.trim();
    final goal = int.tryParse(_goalController.text) ?? 30;
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit name'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final provider = context.read<HabitProvider>();

    if (isEditing) {
      // Update existing habit
      provider.updateHabit(widget.editHabit!.id, name, goal);
      // Update reminder if changed
      if (_reminderEnabled != widget.editHabit!.reminder.enabled ||
          _reminderTime.format(context) != widget.editHabit!.reminder.time) {
        final timeStr =
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
        provider.updateReminder(
          widget.editHabit!.id,
          enabled: _reminderEnabled,
          time: timeStr,
        );
      }
    } else {
      // Create new habit with all options
      final timeStr =
          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
      provider.addHabit(
        name,
        goal,
        description: description,
        category: _selectedCategory,
        color: colorToHex(_selectedColor),
        icon: iconToString(_selectedIcon),
        reminderEnabled: _reminderEnabled,
        reminderTime: timeStr,
      );
    }

    Navigator.pop(context);
  }
}

/// Show the add habit dialog
void showAddHabitDialog(BuildContext context, {Habit? editHabit}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddHabitDialog(editHabit: editHabit),
  );
}
