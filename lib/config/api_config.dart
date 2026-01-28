class ApiConfig {
  // Change this to your backend URL
  // For Android emulator use: http://10.0.2.2:3000
  // For iOS simulator use: http://localhost:3000
  // For physical device use your computer's IP: http://192.168.x.x:3000
  // For web use: http://localhost:3000
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth endpoints
  static const String signUp = '$baseUrl/auth/signup';
  static const String signIn = '$baseUrl/auth/signin';
  static const String me = '$baseUrl/auth/me';

  // Habit endpoints
  static const String habits = '$baseUrl/habits';
  static const String syncHabits = '$baseUrl/habits/sync';
  static const String layoutSettings = '$baseUrl/habits/layout';

  static String toggleHabit(String habitId) =>
      '$baseUrl/habits/$habitId/toggle';
  static String updateHabit(String habitId) => '$baseUrl/habits/$habitId';
  static String deleteHabit(String habitId) => '$baseUrl/habits/$habitId';
}
