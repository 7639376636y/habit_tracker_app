/// Habit categories for organization
enum HabitCategory {
  health,
  fitness,
  productivity,
  mindfulness,
  learning,
  social,
  finance,
  creativity,
  other,
}

/// Frequency type for habit tracking
enum FrequencyType { daily, weekly, specificDays }

/// Streak information for a habit
class HabitStreak {
  final int current;
  final int longest;
  final DateTime? lastCompletedDate;

  HabitStreak({this.current = 0, this.longest = 0, this.lastCompletedDate});

  factory HabitStreak.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HabitStreak();
    return HabitStreak(
      current: json['current'] ?? 0,
      longest: json['longest'] ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current,
    'longest': longest,
    'lastCompletedDate': lastCompletedDate?.toIso8601String(),
  };
}

/// Frequency settings for a habit
class HabitFrequency {
  final FrequencyType type;
  final List<int> daysOfWeek;
  final int timesPerWeek;

  HabitFrequency({
    this.type = FrequencyType.daily,
    this.daysOfWeek = const [],
    this.timesPerWeek = 7,
  });

  factory HabitFrequency.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HabitFrequency();
    return HabitFrequency(
      type: FrequencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FrequencyType.daily,
      ),
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      timesPerWeek: json['timesPerWeek'] ?? 7,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'daysOfWeek': daysOfWeek,
    'timesPerWeek': timesPerWeek,
  };
}

/// Reminder settings for a habit
class HabitReminder {
  final bool enabled;
  final String time;
  final List<int> days;

  HabitReminder({
    this.enabled = false,
    this.time = '09:00',
    this.days = const [],
  });

  factory HabitReminder.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HabitReminder();
    return HabitReminder(
      enabled: json['enabled'] ?? false,
      time: json['time'] ?? '09:00',
      days: List<int>.from(json['days'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'time': time,
    'days': days,
  };
}

class Habit {
  final String? mongoId;
  final int id;
  final String name;
  final String description;
  final HabitCategory category;
  final String color;
  final String icon;
  final int goalDays;
  final Map<DateTime, bool> completedDays;
  final HabitFrequency frequency;
  final HabitReminder reminder;
  final HabitStreak streak;
  // Status flags
  final bool isActive;
  final bool isPaused;
  final DateTime? pausedAt;
  final bool isArchived;
  final DateTime? archivedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  // Ordering & dates
  final int sortOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Habit({
    this.mongoId,
    required this.id,
    required this.name,
    this.description = '',
    this.category = HabitCategory.other,
    this.color = '#4CAF50',
    this.icon = '',
    required this.goalDays,
    Map<DateTime, bool>? completedDays,
    HabitFrequency? frequency,
    HabitReminder? reminder,
    HabitStreak? streak,
    this.isActive = true,
    this.isPaused = false,
    this.pausedAt,
    this.isArchived = false,
    this.archivedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.sortOrder = 0,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  }) : completedDays = completedDays ?? {},
       frequency = frequency ?? HabitFrequency(),
       reminder = reminder ?? HabitReminder(),
       streak = streak ?? HabitStreak();

  int get completedCount => completedDays.values.where((v) => v).length;
  int get leftCount => goalDays - completedCount;
  double get progressPercentage =>
      goalDays > 0 ? (completedCount / goalDays) * 100 : 0;

  bool isCompletedOn(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return completedDays[normalizedDate] ?? false;
  }

  Habit copyWith({
    String? mongoId,
    int? id,
    String? name,
    String? description,
    HabitCategory? category,
    String? color,
    String? icon,
    int? goalDays,
    Map<DateTime, bool>? completedDays,
    HabitFrequency? frequency,
    HabitReminder? reminder,
    HabitStreak? streak,
    bool? isActive,
    bool? isPaused,
    DateTime? pausedAt,
    bool? isArchived,
    DateTime? archivedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    int? sortOrder,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      mongoId: mongoId ?? this.mongoId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      goalDays: goalDays ?? this.goalDays,
      completedDays: completedDays ?? Map.from(this.completedDays),
      frequency: frequency ?? this.frequency,
      reminder: reminder ?? this.reminder,
      streak: streak ?? this.streak,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      pausedAt: pausedAt ?? this.pausedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Habit toggleDay(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final newCompletedDays = Map<DateTime, bool>.from(completedDays);
    newCompletedDays[normalizedDate] =
        !(newCompletedDays[normalizedDate] ?? false);
    return copyWith(completedDays: newCompletedDays);
  }

  /// Parse category from string
  static HabitCategory _parseCategory(String? category) {
    if (category == null) return HabitCategory.other;
    // Map "custom" from backend to "other" in Flutter
    final normalizedCategory = category.toLowerCase() == 'custom'
        ? 'other'
        : category.toLowerCase();
    return HabitCategory.values.firstWhere(
      (e) => e.name == normalizedCategory,
      orElse: () => HabitCategory.other,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final completedDaysJson =
        json['completedDays'] as Map<String, dynamic>? ?? {};
    final completedDays = <DateTime, bool>{};

    completedDaysJson.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        completedDays[date] = value as bool;
      }
    });

    return Habit(
      mongoId: json['id']?.toString(),
      id: json['id'].hashCode,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['category']),
      color: json['color'] ?? '#4CAF50',
      icon: json['icon'] ?? '',
      goalDays: json['goalDays'] ?? 30,
      completedDays: completedDays,
      frequency: HabitFrequency.fromJson(json['frequency']),
      reminder: HabitReminder.fromJson(json['reminder']),
      streak: HabitStreak.fromJson(json['streaks'] ?? json['streak']),
      // Status flags
      isActive: json['isActive'] ?? true,
      isPaused: json['isPaused'] ?? false,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'])
          : null,
      isArchived: json['isArchived'] ?? false,
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      // Ordering & dates
      sortOrder: json['sortOrder'] ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final completedDaysMap = <String, bool>{};
    completedDays.forEach((date, value) {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      completedDaysMap[dateString] = value;
    });

    // Map "other" to "custom" for backend compatibility
    final categoryName = category == HabitCategory.other
        ? 'custom'
        : category.name;

    return {
      if (mongoId != null) 'id': mongoId,
      'name': name,
      'description': description,
      'category': categoryName,
      'color': color,
      'icon': icon,
      'goalDays': goalDays,
      'completedDays': completedDaysMap,
      'frequency': frequency.toJson(),
      'reminder': reminder.toJson(),
      'streaks': streak.toJson(),
      'isActive': isActive,
      'isPaused': isPaused,
      if (pausedAt != null) 'pausedAt': pausedAt!.toIso8601String(),
      'isArchived': isArchived,
      if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'sortOrder': sortOrder,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}
