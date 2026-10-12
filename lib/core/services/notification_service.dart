import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/task_model.dart';
import 'permission_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  static const String channelId = 'task_reminder_channel';
  static const String channelName = 'Pengingat Tugas';
  static const String channelDescription =
      'Notifikasi pengingat tugas tepat waktu';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        if (now.timeZoneOffset.inHours == 7) {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        } else if (now.timeZoneOffset.inHours == 8) {
          tz.setLocalLocation(tz.getLocation('Asia/Makassar'));
        } else if (now.timeZoneOffset.inHours == 9) {
          tz.setLocalLocation(tz.getLocation('Asia/Jayapura'));
        } else {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tap notifikasi membuka aplikasi
      },
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> scheduleTask(Task task) async {
    if (task.selesai) return;

    // Batalkan jadwal lama terlebih dahulu agar tidak duplikat
    await cancelTask(task.notificationId);

    final scheduledDate = tz.TZDateTime.from(task.waktuPengingat, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Jika waktu lampau dan bukan tugas berulang, jangan jadwalkan
    if (scheduledDate.isBefore(now) && task.ulangi == 'tidak') {
      return;
    }

    final hasExactAlarm = await PermissionService.isExactAlarmGranted();
    final scheduleMode = hasExactAlarm
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    DateTimeComponents? matchComponents;
    tz.TZDateTime targetTime = scheduledDate;

    if (task.ulangi == 'harian') {
      matchComponents = DateTimeComponents.time;
      while (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
    } else if (task.ulangi == 'mingguan') {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
      while (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 7));
      }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.notificationId,
      scheduledDate: targetTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: scheduleMode,
      title: task.judul,
      body: task.catatan?.isNotEmpty == true
          ? task.catatan
          : 'Waktunya menyelesaikan tugas Anda',
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<void> cancelTask(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(id: notificationId);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
