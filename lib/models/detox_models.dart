
class Habit {
  final String id;
  final String title;
  final String category;
  final int durationMinutes;
  bool isCompletedToday;

  Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    this.isCompletedToday = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'durationMinutes': durationMinutes,
    'isCompletedToday': isCompletedToday,
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      durationMinutes: json['durationMinutes'],
      isCompletedToday: json['isCompletedToday'] ?? false,
    );
  }
}

class UserStats {
  int minutesSaved;
  int currentStreak;
  int level;
  int points;

  UserStats({
    this.minutesSaved = 0,
    this.currentStreak = 0,
    this.level = 1,
    this.points = 0,
  });

  Map<String, dynamic> toJson() => {
    'minutesSaved': minutesSaved,
    'currentStreak': currentStreak,
    'level': level,
    'points': points,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      minutesSaved: json['minutesSaved'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      level: json['level'] ?? 1,
      points: json['points'] ?? 0,
    );
  }
}
