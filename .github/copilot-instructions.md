# Copilot Instructions for Habit Tracker App

## Architecture Overview

This is a **Flutter web/mobile app** using **Provider** for state management. The app tracks daily habits with calendar-based completion tracking and provides visual progress analytics.

```
lib/
├── main.dart              # App entry, ChangeNotifierProvider setup
├── models/                # Data classes (immutable with copyWith pattern)
├── providers/             # Central state via ChangeNotifier
├── screens/               # Full-page layouts (only HabitTrackerScreen)
└── widgets/               # Reusable UI components
```

### Core Data Flow

1. `HabitProvider` holds all state: habits list, selected month/year, layout settings
2. Widgets use `Consumer<HabitProvider>` or `context.watch<HabitProvider>()` to reactively rebuild
3. State changes call `notifyListeners()` to trigger rebuilds

## Key Conventions

### Model Pattern

Models are **immutable** with `copyWith` methods. See [habit.dart](lib/models/habit.dart):

```dart
// Dates are normalized to midnight for consistent Map lookups
final normalizedDate = DateTime(date.year, date.month, date.day);
```

### Widget Structure

- Each widget is a **standalone Card-style container** with consistent styling:
  - White background, 16px border radius, subtle shadow
  - Gradient header (Indigo→Purple: `0xFF6366F1` → `0xFF8B5CF6`)
- Responsive breakpoints: mobile `<600px`, tablet `600-1100px`, desktop `>1100px`
- Use `MediaQuery.of(context).size.width` to determine layout

### Responsive Layout Pattern

Widgets check screen width and render different layouts:

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isMobile = screenWidth < 600;
if (isMobile) return _buildMobileLayout(...);
return _buildDesktopLayout(...);
```

### Color Palette

Reuse these project colors:

- Primary gradient: `Color(0xFF6366F1)` → `Color(0xFF8B5CF6)`
- Success: `Color(0xFF10B981)`
- Warning: `Color(0xFFF59E0B)`
- Error: `Color(0xFFEF4444)`
- Background: `Color(0xFFF8FAFC)`

## Development Commands

```bash
# Run on Chrome (primary target)
cd habit_tracker_app && flutter run -d chrome

# Get dependencies
flutter pub get
```

## Adding New Features

### New Widget Checklist

1. Create in `lib/widgets/` as `StatelessWidget`
2. Use `Consumer<HabitProvider>` to access state
3. Add to `LayoutSection` enum in [layout_settings.dart](lib/models/layout_settings.dart)
4. Register in `_getSectionWidget()` in [habit_tracker_screen.dart](lib/screens/habit_tracker_screen.dart)

### New Habit Operations

Add methods to `HabitProvider` following existing patterns:

- Update `_habits` list, then call `notifyListeners()`
- Use `copyWith` for immutable updates
