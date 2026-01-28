import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/layout_settings.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/calendar_settings.dart';
import '../widgets/overview_section.dart';
import '../widgets/habit_grid.dart';
import '../widgets/progress_chart.dart';
import '../widgets/monthly_progress_pie.dart';
import '../widgets/top_habits_widget.dart';
import '../widgets/overall_progress_widget.dart';
import '../widgets/layout_customizer.dart';
import '../widgets/empty_habits_view.dart';
import '../widgets/add_habit_dialog.dart';
import 'archived_screen.dart';
import 'trash_screen.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  bool _isEditMode = false;
  int? _draggedIndex;

  Widget _getSectionWidget(LayoutSection section) {
    switch (section) {
      case LayoutSection.calendar:
        return const CalendarSettings();
      case LayoutSection.monthlyProgress:
        return const MonthlyProgressPie();
      case LayoutSection.progressChart:
        return const ProgressChart();
      case LayoutSection.topHabits:
        return const TopHabitsWidget();
      case LayoutSection.overallProgress:
        return const OverallProgressWidget();
      case LayoutSection.overview:
        return const OverviewSection();
      case LayoutSection.habitGrid:
        return const HabitGrid();
    }
  }

  // Get preferred width for each section based on content type
  double _getSectionWidth(
    LayoutSection section,
    double screenWidth,
    bool isDesktop,
    bool isTablet,
  ) {
    final maxWidth = screenWidth - (isDesktop ? 64 : 32);

    // Small widgets that should be compact
    if (section == LayoutSection.calendar ||
        section == LayoutSection.monthlyProgress ||
        section == LayoutSection.topHabits ||
        section == LayoutSection.overallProgress) {
      if (isDesktop) return (maxWidth - 32) / 3; // 3 columns
      if (isTablet) return (maxWidth - 16) / 2; // 2 columns
      return maxWidth; // Full width on mobile
    }

    // Medium widgets - Progress Chart takes 2 column spaces
    if (section == LayoutSection.progressChart) {
      if (isDesktop) return ((maxWidth - 32) / 3) * 2 + 16; // 2 columns width
      return maxWidth;
    }

    // Large widgets - always full width
    return maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;
    final isTablet = screenWidth > 650 && screenWidth <= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refreshHabits(),
            child: CustomScrollView(
              slivers: [
                // Clean App Bar
                SliverAppBar(
                  expandedHeight: isDesktop ? 100 : 120,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: Colors.white,
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.track_changes_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Habit Tracker',
                                      style: TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${provider.monthName} ${provider.selectedYear}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildSyncButton(context, provider),
                              const SizedBox(width: 8),
                              _buildLayoutButton(context),
                              const SizedBox(width: 12),
                              _buildAddButton(context, provider, isDesktop),
                              const SizedBox(width: 12),
                              _buildLogoutButton(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: provider.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : provider.hasHabits
                        ? _buildCustomLayout(
                            context,
                            provider,
                            isDesktop,
                            isTablet,
                          )
                        : EmptyHabitsView(
                            onAddHabit: () => showAddHabitDialog(context),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, HabitProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: provider.isLoading
            ? null
            : () async {
                await provider.refreshHabits();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Habits synced from server'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, color: Color(0xFF64748B), size: 20),
        ),
      ),
    );
  }

  Widget _buildLayoutButton(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit mode toggle
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isEditMode
                    ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: _isEditMode
                    ? Border.all(color: const Color(0xFF6366F1), width: 2)
                    : null,
              ),
              child: Icon(
                _isEditMode ? Icons.done_rounded : Icons.open_with_rounded,
                color: _isEditMode
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Settings button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLayoutCustomizer(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLayoutCustomizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) =>
            LayoutCustomizer(scrollController: scrollController),
      ),
    );
  }

  Widget _buildCustomLayout(
    BuildContext context,
    HabitProvider provider,
    bool isDesktop,
    bool isTablet,
  ) {
    final settings = provider.layoutSettings;
    final visibleSections = settings.visibleOrderedSections;
    final screenWidth = MediaQuery.of(context).size.width;

    if (visibleSections.isEmpty) {
      return _buildEmptyLayoutState(context);
    }

    // Use Wrap for flexible flow layout
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: visibleSections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        final width = _getSectionWidth(
          section,
          screenWidth,
          isDesktop,
          isTablet,
        );

        return _buildDraggableSection(
          context,
          provider,
          section,
          index,
          width,
          visibleSections.length,
        );
      }).toList(),
    );
  }

  Widget _buildDraggableSection(
    BuildContext context,
    HabitProvider provider,
    LayoutSection section,
    int index,
    double width,
    int totalCount,
  ) {
    final isDragging = _draggedIndex == index;

    return LongPressDraggable<int>(
      data: index,
      delay: _isEditMode ? Duration.zero : const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Opacity(opacity: 0.9, child: _getSectionWidget(section)),
        ),
      ),
      childWhenDragging: Container(
        width: width,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                LayoutSettings.getSectionName(section),
                style: TextStyle(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {
          _draggedIndex = index;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _draggedIndex = null;
        });
      },
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) {
          final oldIndex = details.data;
          provider.reorderSections(oldIndex, index);
        },
        builder: (context, candidateData, rejectedData) {
          final isDropTarget = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            decoration: isDropTarget
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1),
                      width: 2,
                    ),
                  )
                : null,
            child: Stack(
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isDragging ? 0.3 : 1.0,
                  child: _getSectionWidget(section),
                ),
                // Edit mode overlay
                if (_isEditMode)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.drag_indicator_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Drag to move',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyLayoutState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'All sections are hidden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the customize button to show sections',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => _showLayoutCustomizer(context),
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: const Text('Customize Layout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: Color(0xFF64748B),
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 48),
      onSelected: (value) {
        switch (value) {
          case 'archived':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ArchivedScreen()),
            );
            break;
          case 'trash':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TrashScreen()),
            );
            break;
          case 'logout':
            _showLogoutConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'archived',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Archived Habits'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'trash',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Trash'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Sign Out'),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset habit provider
              context.read<HabitProvider>().reset();
              // Sign out
              context.read<AuthProvider>().signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    HabitProvider provider,
    bool isDesktop,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAddHabitDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                const Text(
                  'Add Habit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
