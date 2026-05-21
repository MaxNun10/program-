import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_5/models/progress.dart';

void main() {
  group('UserProgress', () {
    test('calculates levels from total XP', () {
      expect(UserProgress.calculateLevel(0), 1);
      expect(UserProgress.calculateLevel(99), 1);
      expect(UserProgress.calculateLevel(100), 2);
      expect(UserProgress.calculateLevel(250), 3);
      expect(UserProgress.calculateLevel(450), 4);
    });

    test('tracks XP progress toward the next level', () {
      final progress = UserProgress(uid: 'user-id', xp: 340);

      expect(progress.getXpForCurrentLevel(), 250);
      expect(progress.getXpForNextLevel(), 450);
      expect(progress.getCurrentLevelProgress(), 90);
      expect(progress.getXpNeededForNextLevel(), 110);
      expect(progress.getProgressPercentage(), 0.45);
    });

    test('loses and refills hearts safely', () {
      final progress = UserProgress(
        uid: 'user-id',
        hearts: 3,
        maxHearts: 5,
        lastHeartRefill: DateTime.now().subtract(const Duration(minutes: 11)),
      );

      expect(progress.refillHeartsIfNeeded(), isTrue);
      expect(progress.hearts, 5);

      expect(progress.loseHeart(), isTrue);
      expect(progress.hearts, 4);
    });
  });
}
