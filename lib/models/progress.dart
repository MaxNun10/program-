class UserProgress {
  final String uid;
  int xp;
  int level;
  int streak;
  String lastActiveDate;

  UserProgress({
    required this.uid,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lastActiveDate = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'level': level,
      'streak': streak,
      'lastActiveDate': lastActiveDate,
    };
  }

  factory UserProgress.fromMap(String uid, Map<String, dynamic> map) {
    return UserProgress(
      uid: uid,
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      streak: map['streak'] as int? ?? 0,
      lastActiveDate: map['lastActiveDate'] as String? ?? '',
    );
  }

  static int calculateLevel(int totalXp) {
    if (totalXp < 100) return 1;
    if (totalXp < 250) return 2;
    if (totalXp < 450) return 3;
    if (totalXp < 700) return 4;
    return 5;
  }

  static String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static int calculateDaysBetween(String date1Str, String date2Str) {
    try {
      final date1 = DateTime.parse(date1Str);
      final date2 = DateTime.parse(date2Str);
      final diff = date2.difference(date1).inDays;
      return diff.abs();
    } catch (e) {
      return -1;
    }
  }

  static bool isYesterday(String dateStr) {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final formattedYesterday = formatDate(yesterday);
      return dateStr == formattedYesterday;
    } catch (e) {
      return false;
    }
  }

  static bool isSameDay(String dateStr) {
    try {
      final today = DateTime.now();
      final formattedToday = formatDate(today);
      return dateStr == formattedToday;
    } catch (e) {
      return false;
    }
  }

  int updateStreak() {
    final today = formatDate(DateTime.now());

    if (isSameDay(lastActiveDate)) {
      return streak;
    }

    if (isYesterday(lastActiveDate)) {
      streak += 1;
    } else {
      streak = 1;
    }

    lastActiveDate = today;
    return streak;
  }
}
