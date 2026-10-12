import 'package:flutter_test/flutter_test.dart';
import 'package:pengingat/models/task_model.dart';

void main() {
  group('Task Model Tests', () {
    test('Task serialization toMap and fromMap works correctly', () {
      final now = DateTime.now();
      final task = Task(
        id: 'task-123',
        judul: 'Bayar Listrik',
        catatan: 'Token PLN 100rb',
        waktuPengingat: now,
        ulangi: 'tidak',
        selesai: false,
        dibuatPada: now,
      );

      final map = task.toMap();
      expect(map['id'], 'task-123');
      expect(map['judul'], 'Bayar Listrik');
      expect(map['catatan'], 'Token PLN 100rb');
      expect(map['waktu_pengingat'], now.millisecondsSinceEpoch);
      expect(map['ulangi'], 'tidak');
      expect(map['selesai'], 0);
      expect(map['dibuat_pada'], now.millisecondsSinceEpoch);

      final fromMap = Task.fromMap(map);
      expect(fromMap.id, task.id);
      expect(fromMap.judul, task.judul);
      expect(fromMap.catatan, task.catatan);
      expect(fromMap.waktuPengingat.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(fromMap.ulangi, task.ulangi);
      expect(fromMap.selesai, false);
    });

    test('Task copyWith updates fields properly', () {
      final now = DateTime.now();
      final task = Task(
        id: 'task-1',
        judul: 'Test',
        waktuPengingat: now,
        dibuatPada: now,
      );

      final updated = task.copyWith(selesai: true, judul: 'Test Selesai');
      expect(updated.selesai, true);
      expect(updated.judul, 'Test Selesai');
      expect(updated.id, 'task-1');
    });

    test('notificationId generates positive 31-bit integer', () {
      final now = DateTime.now();
      final task = Task(
        id: 'unique-id-999',
        judul: 'Test',
        waktuPengingat: now,
        dibuatPada: now,
      );
      expect(task.notificationId >= 0, isTrue);
      expect(task.notificationId <= 0x7FFFFFFF, isTrue);
    });
  });
}
