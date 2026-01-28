import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/habit.dart';
import '../models/layout_settings.dart';
import '../providers/habit_provider.dart';
import 'auth_service.dart';

class HabitService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all habits with limits
  Future<Map<String, dynamic>> getHabitsWithLimits() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.habits),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final habitsJson = data['habits'] as List;
        final habits = habitsJson.map((json) => Habit.fromJson(json)).toList();
        final limits = HabitLimits.fromJson(data['limits']);
        return {'habits': habits, 'limits': limits};
      }
      return {'habits': <Habit>[], 'limits': HabitLimits()};
    } catch (e) {
      debugPrint('Error getting habits: $e');
      return {'habits': <Habit>[], 'limits': HabitLimits()};
    }
  }

  // Get all habits (legacy)
  Future<List<Habit>> getHabits() async {
    final result = await getHabitsWithLimits();
    return result['habits'] as List<Habit>;
  }

  // Create habit with all fields
  Future<Map<String, dynamic>?> createHabit(
    String name,
    int goalDays, {
    String? description,
    String? category,
    String? color,
    String? icon,
    bool reminderEnabled = false,
    String? reminderTime,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'name': name,
        'goalDays': goalDays,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        'reminderEnabled': reminderEnabled,
        if (reminderTime != null) 'reminderTime': reminderTime,
      };

      debugPrint('Creating habit: $body');
      debugPrint('API URL: ${ApiConfig.habits}');

      final response = await http.post(
        Uri.parse(ApiConfig.habits),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'habit': Habit.fromJson(data['habit']),
          'limits': HabitLimits.fromJson(data['limits']),
        };
      } else if (response.statusCode == 403) {
        // Habit limit reached
        final data = jsonDecode(response.body);
        throw Exception(data['message']);
      } else {
        // Log other errors
        debugPrint(
          'Failed to create habit: ${response.statusCode} - ${response.body}',
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error creating habit: $e');
      rethrow;
    }
  }

  // Update habit with all fields
  Future<Habit?> updateHabit(
    String habitId,
    String name,
    int goalDays, {
    String? description,
    String? category,
    String? color,
    String? icon,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'name': name,
        'goalDays': goalDays,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      };

      final response = await http.put(
        Uri.parse(ApiConfig.updateHabit(habitId)),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating habit: $e');
      return null;
    }
  }

  // Delete habit (soft delete)
  Future<bool> deleteHabit(String habitId, {bool permanent = false}) async {
    try {
      final headers = await _getHeaders();
      final url = permanent
          ? '${ApiConfig.deleteHabit(habitId)}?permanent=true'
          : ApiConfig.deleteHabit(habitId);

      final response = await http.delete(Uri.parse(url), headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      return false;
    }
  }

  // Archive habit
  Future<bool> archiveHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/archive'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error archiving habit: $e');
      return false;
    }
  }

  // Restore archived habit
  Future<Habit?> restoreHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/restore'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error restoring habit: $e');
      return null;
    }
  }

  // Get archived habits
  Future<List<Habit>> getArchivedHabits() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/archived'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final habitsJson = data['habits'] as List;
        return habitsJson.map((json) => Habit.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting archived habits: $e');
      return [];
    }
  }

  // Get paused habits
  Future<List<Habit>> getPausedHabits() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/paused'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final habitsJson = data['habits'] as List;
        return habitsJson.map((json) => Habit.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting paused habits: $e');
      return [];
    }
  }

  // Get deleted habits (trash)
  Future<List<Habit>> getTrashHabits() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/trash'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final habitsJson = data['habits'] as List;
        return habitsJson.map((json) => Habit.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting trash habits: $e');
      return [];
    }
  }

  // Pause habit
  Future<Habit?> pauseHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/pause'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error pausing habit: $e');
      return null;
    }
  }

  // Resume habit
  Future<Habit?> resumeHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/resume'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error resuming habit: $e');
      return null;
    }
  }

  // Update reminder
  Future<Habit?> updateReminder(
    String habitId, {
    bool? enabled,
    String? time,
    List<int>? days,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (enabled != null) body['enabled'] = enabled;
      if (time != null) body['time'] = time;
      if (days != null) body['days'] = days;

      final response = await http.put(
        Uri.parse('${ApiConfig.habits}/$habitId/reminder'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      return null;
    }
  }

  // Get streak details for a habit
  Future<Map<String, dynamic>?> getStreakDetails(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/$habitId/streaks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting streak details: $e');
      return null;
    }
  }

  // Get all streaks summary
  Future<Map<String, dynamic>?> getAllStreaks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/streaks/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting all streaks: $e');
      return null;
    }
  }

  // Duplicate habit
  Future<Habit?> duplicateHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/duplicate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        throw Exception(data['message']);
      }
      return null;
    } catch (e) {
      debugPrint('Error duplicating habit: $e');
      rethrow;
    }
  }

  // Restore from trash
  Future<Habit?> restoreFromTrash(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/restore-from-trash'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error restoring from trash: $e');
      return null;
    }
  }

  // Empty trash
  Future<int> emptyTrash() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.habits}/trash/empty'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['deletedCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error emptying trash: $e');
      return 0;
    }
  }

  // Get single habit
  Future<Habit?> getHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/$habitId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting habit: $e');
      return null;
    }
  }

  // Bulk archive
  Future<int> bulkArchive(List<String> habitIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/bulk/archive'),
        headers: headers,
        body: jsonEncode({'habitIds': habitIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['modifiedCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error bulk archiving: $e');
      return 0;
    }
  }

  // Bulk delete
  Future<int> bulkDelete(
    List<String> habitIds, {
    bool permanent = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/bulk/delete'),
        headers: headers,
        body: jsonEncode({'habitIds': habitIds, 'permanent': permanent}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['modifiedCount'] ?? data['deletedCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error bulk deleting: $e');
      return 0;
    }
  }

  // Bulk pause
  Future<int> bulkPause(List<String> habitIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/bulk/pause'),
        headers: headers,
        body: jsonEncode({'habitIds': habitIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['modifiedCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error bulk pausing: $e');
      return 0;
    }
  }

  // Bulk resume
  Future<int> bulkResume(List<String> habitIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/bulk/resume'),
        headers: headers,
        body: jsonEncode({'habitIds': habitIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['modifiedCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error bulk resuming: $e');
      return 0;
    }
  }

  // Get habits with reminders
  Future<List<Habit>> getHabitsWithReminders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/reminders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final habitsJson = data['habits'] as List;
        return habitsJson.map((json) => Habit.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting habits with reminders: $e');
      return [];
    }
  }

  // Get completions for date range
  Future<Map<String, dynamic>?> getCompletionsRange(
    String startDate,
    String endDate,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.habits}/completions/range?startDate=$startDate&endDate=$endDate',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting completions range: $e');
      return null;
    }
  }

  // Get monthly stats
  Future<Map<String, dynamic>?> getMonthlyStats(int year, int month) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/stats/monthly?year=$year&month=$month'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting monthly stats: $e');
      return null;
    }
  }

  // Toggle day
  Future<Habit?> toggleDay(String habitId, DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateString = _formatDate(date);

      final response = await http.post(
        Uri.parse(ApiConfig.toggleHabit(habitId)),
        headers: headers,
        body: jsonEncode({'date': dateString}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error toggling day: $e');
      return null;
    }
  }

  // Reorder habits
  Future<bool> reorderHabits(List<String> habitIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.habits}/reorder'),
        headers: headers,
        body: jsonEncode({'habitIds': habitIds}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error reordering habits: $e');
      return false;
    }
  }

  // Add note to habit
  Future<Habit?> addNote(String habitId, DateTime date, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.habits}/$habitId/note'),
        headers: headers,
        body: jsonEncode({'date': date.toIso8601String(), 'content': content}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Habit.fromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return null;
    }
  }

  // Sync all habits
  Future<Map<String, dynamic>> syncHabits(List<Habit> habits) async {
    try {
      final headers = await _getHeaders();
      final habitsJson = habits.map((h) => h.toJson()).toList();

      final response = await http.post(
        Uri.parse(ApiConfig.syncHabits),
        headers: headers,
        body: jsonEncode({'habits': habitsJson}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultHabits = data['habits'] as List;
        return {
          'habits': resultHabits.map((json) => Habit.fromJson(json)).toList(),
          'limits': HabitLimits.fromJson(data['limits']),
        };
      }
      return {'habits': habits, 'limits': HabitLimits()};
    } catch (e) {
      debugPrint('Error syncing habits: $e');
      return {'habits': habits, 'limits': HabitLimits()};
    }
  }

  // Get habit categories
  Future<Map<String, dynamic>?> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.habits}/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return null;
    }
  }

  // ========== Layout Settings Methods ==========

  // Get layout settings from backend
  Future<LayoutSettings?> getLayoutSettings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.layoutSettings),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['layoutSettings'] != null) {
          return LayoutSettings.fromJson(data['layoutSettings']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting layout settings: $e');
      return null;
    }
  }

  // Save layout settings to backend
  Future<LayoutSettings?> saveLayoutSettings(LayoutSettings settings) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.layoutSettings),
        headers: headers,
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['layoutSettings'] != null) {
          return LayoutSettings.fromJson(data['layoutSettings']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error saving layout settings: $e');
      return null;
    }
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
