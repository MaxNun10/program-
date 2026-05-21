class UserProgress {
  static const List<int> levelXpThresholds = [0, 100, 250, 450, 700];
  static const int defaultMaxHearts = 5;
  static const int heartRefillMinutes = 5;

  final String uid;
  int xp;
  int level;
  int streak;
  String lastActiveDate;
  List<String> completedLessons;
  int dailyGoal;
  int todayXp;
  String lastGoalResetDate;
  String lastGoalCompletedDate;
  String lastGoalCelebrationDate;
  int hearts;
  int maxHearts;
  DateTime lastHeartRefill;

  UserProgress({
    required this.uid,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lastActiveDate = '',
    List<String>? completedLessons,
    this.dailyGoal = 50,
    this.todayXp = 0,
    this.lastGoalResetDate = '',
    this.lastGoalCompletedDate = '',
    this.lastGoalCelebrationDate = '',
    this.hearts = defaultMaxHearts,
    this.maxHearts = defaultMaxHearts,
    DateTime? lastHeartRefill,
  }) : completedLessons = completedLessons ?? [],
       lastHeartRefill = lastHeartRefill ?? DateTime.now();

  void markLessonCompleted(String lessonId) {
    if (!completedLessons.contains(lessonId)) {
      completedLessons.add(lessonId);
    }
  }

  int get effectiveDailyGoal => dailyGoal <= 0 ? 50 : dailyGoal;

  bool get isDailyGoalCompleted => todayXp >= effectiveDailyGoal;

  bool get shouldCelebrateDailyGoal {
    return isDailyGoalCompleted &&
        lastGoalResetDate.isNotEmpty &&
        lastGoalCelebrationDate != lastGoalResetDate;
  }

  bool resetDailyGoalIfNeeded() {
    final today = formatDate(DateTime.now());
    if (lastGoalResetDate == today) {
      return false;
    }

    todayXp = 0;
    lastGoalResetDate = today;
    lastGoalCompletedDate = '';
    lastGoalCelebrationDate = '';
    return true;
  }

  void addDailyXp(int xpEarned) {
    final wasCompleted = isDailyGoalCompleted;
    todayXp += xpEarned;
    if (!wasCompleted && isDailyGoalCompleted) {
      lastGoalCompletedDate = lastGoalResetDate;
    }
  }

  void markDailyGoalCelebrated() {
    if (lastGoalResetDate.isNotEmpty) {
      lastGoalCelebrationDate = lastGoalResetDate;
    }
  }

  bool refillHeartsIfNeeded() {
    final now = DateTime.now();
    final safeMaxHearts = maxHearts <= 0 ? defaultMaxHearts : maxHearts;
    var changed = false;

    if (maxHearts != safeMaxHearts) {
      maxHearts = safeMaxHearts;
      changed = true;
    }

    final clampedHearts = hearts.clamp(0, maxHearts).toInt();
    if (hearts != clampedHearts) {
      hearts = clampedHearts;
      changed = true;
    }

    if (hearts >= maxHearts) {
      return changed;
    }

    final elapsedMinutes = now.difference(lastHeartRefill).inMinutes;
    if (elapsedMinutes < heartRefillMinutes) {
      return changed;
    }

    final heartsToAdd = elapsedMinutes ~/ heartRefillMinutes;
    hearts = (hearts + heartsToAdd).clamp(0, maxHearts).toInt();
    lastHeartRefill = lastHeartRefill.add(
      Duration(minutes: heartsToAdd * heartRefillMinutes),
    );

    if (hearts >= maxHearts) {
      lastHeartRefill = now;
    }

    return true;
  }

  bool loseHeart() {
    refillHeartsIfNeeded();
    if (hearts <= 0) return false;

    hearts -= 1;
    if (hearts < maxHearts) {
      lastHeartRefill = DateTime.now();
    }
    return true;
  }

  String getHeartRefillText() {
    refillHeartsIfNeeded();
    if (hearts >= maxHearts) return 'Full hearts';

    final nextRefill = lastHeartRefill.add(
      const Duration(minutes: heartRefillMinutes),
    );
    final remaining = nextRefill.difference(DateTime.now());
    if (remaining.inSeconds <= 0) return 'Next heart soon';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return 'Next heart in ${minutes}m ${seconds}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'level': level,
      'streak': streak,
      'lastActiveDate': lastActiveDate,
      'completedLessons': completedLessons,
      'dailyGoal': dailyGoal,
      'todayXp': todayXp,
      'lastGoalResetDate': lastGoalResetDate,
      'lastGoalCompletedDate': lastGoalCompletedDate,
      'lastGoalCelebrationDate': lastGoalCelebrationDate,
      'hearts': hearts,
      'maxHearts': maxHearts,
      'lastHeartRefill': lastHeartRefill,
    };
  }

  factory UserProgress.fromMap(String uid, Map<String, dynamic> map) {
    final completedLessonsData = map['completedLessons'];
    final completedLessons = completedLessonsData is List
        ? completedLessonsData.whereType<String>().toList()
        : <String>[];

    return UserProgress(
      uid: uid,
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      streak: map['streak'] as int? ?? 0,
      lastActiveDate: map['lastActiveDate'] as String? ?? '',
      completedLessons: completedLessons,
      dailyGoal: (map['dailyGoal'] as num?)?.toInt() ?? 50,
      todayXp: (map['todayXp'] as num?)?.toInt() ?? 0,
      lastGoalResetDate: map['lastGoalResetDate'] as String? ?? '',
      lastGoalCompletedDate: map['lastGoalCompletedDate'] as String? ?? '',
      lastGoalCelebrationDate:
          map['lastGoalCelebrationDate'] as String? ?? '',
      hearts: (map['hearts'] as num?)?.toInt() ?? defaultMaxHearts,
      maxHearts: (map['maxHearts'] as num?)?.toInt() ?? defaultMaxHearts,
      lastHeartRefill: _parseDateTime(map['lastHeartRefill']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    final millisecondsSinceEpoch = value?.millisecondsSinceEpoch;
    if (millisecondsSinceEpoch is int) {
      return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }

    return DateTime.now();
  }

  static int getXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level <= levelXpThresholds.length) {
      return levelXpThresholds[level - 1];
    }

    return levelXpThresholds.last + ((level - levelXpThresholds.length) * 300);
  }

  static int calculateLevel(int totalXp) {
    final safeXp = totalXp < 0 ? 0 : totalXp;
    var calculatedLevel = 1;

    while (safeXp >= getXpForLevel(calculatedLevel + 1)) {
      calculatedLevel++;
    }

    return calculatedLevel;
  }

  int getXpForCurrentLevel() {
    return getXpForLevel(calculateLevel(xp));
  }

  int getXpForNextLevel() {
    return getXpForLevel(calculateLevel(xp) + 1);
  }

  int getCurrentLevelProgress() {
    final currentLevelXp = getXpForCurrentLevel();
    final nextLevelXp = getXpForNextLevel();
    final levelRange = nextLevelXp - currentLevelXp;
    if (levelRange <= 0) return 0;

    final currentProgress = xp - currentLevelXp;
    return currentProgress.clamp(0, levelRange).toInt();
  }

  double getProgressPercentage() {
    final currentLevelXp = getXpForCurrentLevel();
    final nextLevelXp = getXpForNextLevel();
    final levelRange = nextLevelXp - currentLevelXp;
    if (levelRange <= 0) return 0;

    return getCurrentLevelProgress() / levelRange;
  }

  int getXpNeededForNextLevel() {
    final remainingXp = getXpForNextLevel() - xp;
    return remainingXp < 0 ? 0 : remainingXp;
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
