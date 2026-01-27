import 'package:flutter/material.dart';

enum LayoutSection {
  progressChart,
  monthlyProgress,
  habitGrid,
  overview,
  calendar,
  overallProgress,
  topHabits,
}

class LayoutSettings {
  final List<LayoutSection> sectionOrder;
  final Map<LayoutSection, bool> visibleSections;
  final int columnsDesktop;
  final int columnsTablet;

  const LayoutSettings({
    required this.sectionOrder,
    required this.visibleSections,
    this.columnsDesktop = 3,
    this.columnsTablet = 2,
  });

  factory LayoutSettings.defaultSettings() {
    return LayoutSettings(
      sectionOrder: LayoutSection.values.toList(),
      visibleSections: {
        for (var section in LayoutSection.values) section: true,
      },
      columnsDesktop: 3,
      columnsTablet: 2,
    );
  }

  LayoutSettings copyWith({
    List<LayoutSection>? sectionOrder,
    Map<LayoutSection, bool>? visibleSections,
    int? columnsDesktop,
    int? columnsTablet,
  }) {
    return LayoutSettings(
      sectionOrder: sectionOrder ?? this.sectionOrder,
      visibleSections: visibleSections ?? this.visibleSections,
      columnsDesktop: columnsDesktop ?? this.columnsDesktop,
      columnsTablet: columnsTablet ?? this.columnsTablet,
    );
  }

  bool isSectionVisible(LayoutSection section) {
    return visibleSections[section] ?? true;
  }

  List<LayoutSection> get visibleOrderedSections {
    return sectionOrder.where((s) => isSectionVisible(s)).toList();
  }

  static String getSectionName(LayoutSection section) {
    switch (section) {
      case LayoutSection.calendar:
        return 'Calendar Settings';
      case LayoutSection.monthlyProgress:
        return 'Monthly Progress';
      case LayoutSection.progressChart:
        return 'Progress Chart';
      case LayoutSection.topHabits:
        return 'Top Habits';
      case LayoutSection.overallProgress:
        return 'Overall Progress';
      case LayoutSection.overview:
        return 'Weekly Overview';
      case LayoutSection.habitGrid:
        return 'Habit Grid';
    }
  }

  static IconData getSectionIcon(LayoutSection section) {
    switch (section) {
      case LayoutSection.calendar:
        return Icons.calendar_month_rounded;
      case LayoutSection.monthlyProgress:
        return Icons.pie_chart_rounded;
      case LayoutSection.progressChart:
        return Icons.show_chart_rounded;
      case LayoutSection.topHabits:
        return Icons.leaderboard_rounded;
      case LayoutSection.overallProgress:
        return Icons.analytics_rounded;
      case LayoutSection.overview:
        return Icons.view_week_rounded;
      case LayoutSection.habitGrid:
        return Icons.grid_view_rounded;
    }
  }
}
