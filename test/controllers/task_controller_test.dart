import 'package:flutter_test/flutter_test.dart';
import 'package:pengingat/models/task_model.dart';

void main() {
  group('Task Partition Logic Tests', () {
    test('Separates today/urgent tasks from future tasks correctly', () {
      final now = DateTime.now();
      final todayUrgent = Task(
        id: '1',
        judul: 'Tugas Hari Ini',
        waktuPengingat: DateTime(now.year, now.month, now.day, 23, 59),
        selesai: false,
        dibuatPada: now,
      );
      final tomorrowTask = Task(
        id: '2',
        judul: 'Tugas Besok',
        waktuPengingat: DateTime(now.year, now.month, now.day + 1, 10, 0),
        selesai: false,
        dibuatPada: now,
      );
      final completedToday = Task(
        id: '3',
        judul: 'Tugas Hari Ini Selesai',
        waktuPengingat: DateTime(now.year, now.month, now.day, 12, 0),
        selesai: true,
        dibuatPada: now,
      );

      final endOfToday =
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final isUrgent1 =
          !todayUrgent.selesai && !todayUrgent.waktuPengingat.isAfter(endOfToday);
      final isUrgent2 =
          !tomorrowTask.selesai && !tomorrowTask.waktuPengingat.isAfter(endOfToday);
      final isUrgent3 = !completedToday.selesai &&
          !completedToday.waktuPengingat.isAfter(endOfToday);

      expect(isUrgent1, isTrue);
      expect(isUrgent2, isFalse);
      expect(isUrgent3, isFalse);
    });
  });
}
