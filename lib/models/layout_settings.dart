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
        LayoutSection.progressChart: true,
        LayoutSection.monthlyProgress: true,
        LayoutSection.habitGrid: true,
        LayoutSection.overview: true,
        LayoutSection.calendar: false, // Hide calendar by default
        LayoutSection.overallProgress: true,
        LayoutSection.topHabits: true,
      },
      columnsDesktop: 3,
      columnsTablet: 2,
    );
  }

  /// Parse LayoutSection from string
  static LayoutSection? _parseSection(String? name) {
    if (name == null) return null;
    try {
      return LayoutSection.values.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Create from JSON (backend response)
  factory LayoutSettings.fromJson(Map<String, dynamic> json) {
    // Parse section order
    final sectionOrderJson = json['sectionOrder'] as List<dynamic>? ?? [];
    final sectionOrder = sectionOrderJson
        .map((s) => _parseSection(s.toString()))
        .whereType<LayoutSection>()
        .toList();

    // If empty, use defaults
    final finalSectionOrder = sectionOrder.isNotEmpty
        ? sectionOrder
        : LayoutSection.values.toList();

    // Parse visible sections
    final visibleSectionsJson =
        json['visibleSections'] as Map<String, dynamic>? ?? {};
    final defaultSettings = LayoutSettings.defaultSettings();
    final visibleSections = <LayoutSection, bool>{};
    for (var section in LayoutSection.values) {
      final key = section.name;
      visibleSections[section] =
          visibleSectionsJson[key] ??
          defaultSettings.visibleSections[section] ??
          true;
    }

    return LayoutSettings(
      sectionOrder: finalSectionOrder,
      visibleSections: visibleSections,
      columnsDesktop: json['columnsDesktop'] ?? 3,
      columnsTablet: json['columnsTablet'] ?? 2,
    );
  }

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'sectionOrder': sectionOrder.map((s) => s.name).toList(),
      'visibleSections': {
        for (var entry in visibleSections.entries) entry.key.name: entry.value,
      },
      'columnsDesktop': columnsDesktop,
      'columnsTablet': columnsTablet,
    };
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
    // Always hide calendar regardless of settings
    if (section == LayoutSection.calendar) {
      return false;
    }
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
