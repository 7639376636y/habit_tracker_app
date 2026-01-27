class Habit {
  final int id;
  final String name;
  final int goalDays;
  final Map<DateTime, bool> completedDays;

  Habit({
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
    int? id,
    String? name,
    int? goalDays,
    Map<DateTime, bool>? completedDays,
  }) {
    return Habit(
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
}
