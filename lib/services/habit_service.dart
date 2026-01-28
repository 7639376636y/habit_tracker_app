import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/habit.dart';
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

  // Get all habits
  Future<List<Habit>> getHabits() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.habits),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final habitsJson = data['habits'] as List;
        return habitsJson.map((json) => _habitFromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting habits: $e');
      return [];
    }
  }

  // Create habit
  Future<Habit?> createHabit(String name, int goalDays) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.habits),
        headers: headers,
        body: jsonEncode({'name': name, 'goalDays': goalDays}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _habitFromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating habit: $e');
      return null;
    }
  }

  // Update habit
  Future<Habit?> updateHabit(String habitId, String name, int goalDays) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.updateHabit(habitId)),
        headers: headers,
        body: jsonEncode({'name': name, 'goalDays': goalDays}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _habitFromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating habit: $e');
      return null;
    }
  }

  // Delete habit
  Future<bool> deleteHabit(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteHabit(habitId)),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      return false;
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
        return _habitFromJson(data['habit']);
      }
      return null;
    } catch (e) {
      debugPrint('Error toggling day: $e');
      return null;
    }
  }

  // Sync all habits
  Future<List<Habit>> syncHabits(List<Habit> habits) async {
    try {
      final headers = await _getHeaders();
      final habitsJson = habits.map((h) => _habitToJson(h)).toList();

      final response = await http.post(
        Uri.parse(ApiConfig.syncHabits),
        headers: headers,
        body: jsonEncode({'habits': habitsJson}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultHabits = data['habits'] as List;
        return resultHabits.map((json) => _habitFromJson(json)).toList();
      }
      return habits;
    } catch (e) {
      debugPrint('Error syncing habits: $e');
      return habits;
    }
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Convert JSON to Habit
  Habit _habitFromJson(Map<String, dynamic> json) {
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

    final mongoId = json['id']?.toString() ?? '';
    return Habit(
      mongoId: mongoId,
      id: mongoId.hashCode, // Convert MongoDB ObjectId to int
      name: json['name'],
      goalDays: json['goalDays'],
      completedDays: completedDays,
    );
  }

  // Convert Habit to JSON
  Map<String, dynamic> _habitToJson(Habit habit) {
    final completedDays = <String, bool>{};
    habit.completedDays.forEach((date, value) {
      completedDays[_formatDate(date)] = value;
    });

    return {
      'name': habit.name,
      'goalDays': habit.goalDays,
      'completedDays': completedDays,
    };
  }
}
