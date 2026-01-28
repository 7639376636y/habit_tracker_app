class Habit {
  final String? mongoId; // MongoDB ObjectId
  final int id; // Local int id for UI
  final String name;
  final int goalDays;
  final Map<DateTime, bool> completedDays;

  Habit({
    this.mongoId,
    required this.id,
    required this.name,
    required this.goalDays,
    Map<DateTime, bool>? completedDays,
  }) : completedDays = completedDays ?? {};

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
    int? goalDays,
    Map<DateTime, bool>? completedDays,
  }) {
    return Habit(
      mongoId: mongoId ?? this.mongoId,
      id: id ?? this.id,
      name: name ?? this.name,
      goalDays: goalDays ?? this.goalDays,
      completedDays: completedDays ?? Map.from(this.completedDays),
    );
  }

  Habit toggleDay(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final newCompletedDays = Map<DateTime, bool>.from(completedDays);
    newCompletedDays[normalizedDate] =
        !(newCompletedDays[normalizedDate] ?? false);
    return copyWith(completedDays: newCompletedDays);
  }

  // JSON serialization for API
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
      name: json['name'],
      goalDays: json['goalDays'],
      completedDays: completedDays,
    );
  }

  Map<String, dynamic> toJson() {
    final completedDaysMap = <String, bool>{};
    completedDays.forEach((date, value) {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      completedDaysMap[dateString] = value;
    });

    return {
      if (mongoId != null) 'id': mongoId,
      'name': name,
      'goalDays': goalDays,
      'completedDays': completedDaysMap,
    };
  }
}
