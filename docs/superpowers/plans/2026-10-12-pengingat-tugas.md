# Pengingat Tugas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build offline-first task reminder Android app with exact alarm notifications and dark masculine UI.

**Architecture:** Model-Repository-Controller (ChangeNotifier) pattern using sqflite for local persistence and flutter_local_notifications for exact alarms.

**Tech Stack:** Flutter 3.47+ (Dart 3.13+), sqflite, flutter_local_notifications, timezone, permission_handler, intl.

**Spec:** C:\Users\NAN\Desktop\pengingat\docs\superpowers\specs\2026-10-12-pengingat-tugas-design.md

## Global Constraints
- minSdk 26, compileSdk 34+, targetSdk 34+.
- Package ID: `com.taskreminder`.
- App Name: `Pengingat`.
- Palet Warna: Background `#121212`, Card `#1E1E1E`, Amber `#FF9800`, Text `#E0E0E0`, Muted `#757575`.
- Bahasa: Bahasa Indonesia.
- Static analysis: `flutter analyze` 0 errors, 0 warnings.
- Test coverage: `flutter test` 100% pass.
- No git commits or pushes unless explicitly instructed by user.

## Review Focus
1. Exact alarm permission revoked in system settings -> app must fallback to inexact alarm gracefully without crashing.
2. Reminder scheduled in the past on form submit -> validation must block submission and alert user.
3. Empty task title on form submit -> validation must show red highlight and error snackbar.
4. Device reboot or app restart -> pending tasks must be re-scheduled into flutter_local_notifications.
5. Task completion / deletion -> existing notification ID must be cancelled so alarm doesn't fire.

---

### Task 1: Setup Proyek Flutter & Konfigurasi Android

**Files:**
- Create: `pubspec.yaml` (via `flutter create`)
- Modify: `android/app/build.gradle.kts` (or `build.gradle`)
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: Project skeleton with package `com.taskreminder`, minSdk 26, required Android permissions, and dependencies declared.

- [ ] **Step 1: Scaffolding proyek Flutter**

Run:
```bash
flutter create --org com --project-name pengingat --platforms android C:/Users/NAN/Desktop/pengingat
```

- [ ] **Step 2: Tambahkan dependensi ke pubspec.yaml**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter pub add sqflite path flutter_local_notifications timezone permission_handler intl
```

- [ ] **Step 3: Konfigurasi minSdk 26 & nama aplikasi di Android**

Edit `android/app/build.gradle.kts` (atau `build.gradle`):
Set `minSdk = 26` (atau `minSdkVersion 26`).
Edit `android/app/src/main/AndroidManifest.xml`:
Set `android:label="Pengingat"`.

- [ ] **Step 4: Daftarkan permission di AndroidManifest.xml**

Tambahkan permission sebelum tag `<application>` di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
```

- [ ] **Step 5: Verifikasi dependensi & analisis**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter pub get
flutter analyze
```
Expected: 0 errors.

---

### Task 2: Model & Skema Database Lokal (SQLite)

**Files:**
- Create: `lib/models/task_model.dart`
- Create: `lib/core/services/database_service.dart`
- Create: `test/models/task_model_test.dart`

**Interfaces:**
- Produces: `Task` model class with `toMap()` and `fromMap()`, `DatabaseService` singleton with `tasks` table creation.

- [ ] **Step 1: Tulis unit test untuk Task model**

Create `test/models/task_model_test.dart`:
```dart
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
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal (TDD RED)**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter test test/models/task_model_test.dart
```
Expected: FAIL (file `lib/models/task_model.dart` belum ada).

- [ ] **Step 3: Implementasikan Task model**

Create `lib/models/task_model.dart`:
```dart
class Task {
  final String id;
  final String judul;
  final String? catatan;
  final DateTime waktuPengingat;
  final String ulangi; // 'tidak', 'harian', 'mingguan'
  final bool selesai;
  final DateTime dibuatPada;

  Task({
    required this.id,
    required this.judul,
    this.catatan,
    required this.waktuPengingat,
    this.ulangi = 'tidak',
    this.selesai = false,
    required this.dibuatPada,
  });

  int get notificationId => id.hashCode.abs() & 0x7FFFFFFF;

  Task copyWith({
    String? id,
    String? judul,
    String? catatan,
    DateTime? waktuPengingat,
    String? ulangi,
    bool? selesai,
    DateTime? dibuatPada,
  }) {
    return Task(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      catatan: catatan ?? this.catatan,
      waktuPengingat: waktuPengingat ?? this.waktuPengingat,
      ulangi: ulangi ?? this.ulangi,
      selesai: selesai ?? this.selesai,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'catatan': catatan,
      'waktu_pengingat': waktuPengingat.millisecondsSinceEpoch,
      'ulangi': ulangi,
      'selesai': selesai ? 1 : 0,
      'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      judul: map['judul'] as String,
      catatan: map['catatan'] as String?,
      waktuPengingat: DateTime.fromMillisecondsSinceEpoch(map['waktu_pengingat'] as int),
      ulangi: map['ulangi'] as String? ?? 'tidak',
      selesai: (map['selesai'] as int) == 1,
      dibuatPada: DateTime.fromMillisecondsSinceEpoch(map['dibuat_pada'] as int),
    );
  }
}
```

- [ ] **Step 4: Jalankan test untuk memverifikasi berhasil (TDD GREEN)**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter test test/models/task_model_test.dart
```
Expected: PASS.

- [ ] **Step 5: Implementasikan DatabaseService**

Create `lib/core/services/database_service.dart`:
```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_reminder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        judul TEXT NOT NULL,
        catatan TEXT,
        waktu_pengingat INTEGER NOT NULL,
        ulangi TEXT NOT NULL DEFAULT 'tidak',
        selesai INTEGER NOT NULL DEFAULT 0,
        dibuat_pada INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_waktu ON tasks (waktu_pengingat ASC, selesai ASC)
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
```

---

### Task 3: Permission Service & Notification Service

**Files:**
- Create: `lib/core/services/permission_service.dart`
- Create: `lib/core/services/notification_service.dart`

**Interfaces:**
- Consumes: `permission_handler`, `flutter_local_notifications`, `timezone`, `Task` model.
- Produces: `PermissionService.requestNotificationPermission()`, `checkExactAlarmPermission()`, `NotificationService.scheduleTask()`, `cancelTask()`.

- [ ] **Step 1: Implementasikan PermissionService**

Create `lib/core/services/permission_service.dart`:
```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static Future<bool> isExactAlarmGranted() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  static Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
```

- [ ] **Step 2: Implementasikan NotificationService dengan timezone & exact alarm**

Create `lib/core/services/notification_service.dart`:
```dart
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
  static const String channelDescription = 'Notifikasi pengingat tugas tepat waktu';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    // Default local location fallback jika perangkat belum set
    try {
      final String currentTimeZone = DateTime.now().timeZoneName;
      // Inisialisasi zona waktu perangkat
      tz.setLocalLocation(tz.getLocation(tz.local.name));
    } catch (_) {
      // Fallback ke UTC jika nama timezone perangkat gagal di-parse
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Klik notifikasi membuka aplikasi
      },
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> scheduleTask(Task task) async {
    // Jangan jadwalkan jika sudah selesai
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
      task.notificationId,
      task.judul,
      task.catatan?.isNotEmpty == true ? task.catatan : 'Waktunya menyelesaikan tugas Anda',
      targetTime,
      notificationDetails,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<void> cancelTask(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
```

- [ ] **Step 3: Verifikasi static analysis**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter analyze
```
Expected: 0 errors.

---

### Task 4: Task Repository & Task Controller (State Management)

**Files:**
- Create: `lib/repositories/task_repository.dart`
- Create: `lib/controllers/task_controller.dart`
- Create: `test/controllers/task_controller_test.dart`

**Interfaces:**
- Consumes: `Task`, `DatabaseService`, `NotificationService`.
- Produces: `TaskRepository` CRUD operations, `TaskController` (`ChangeNotifier`) with `tasks`, `mendesakTasks`, `berikutnyaTasks`, `addTask()`, `updateTask()`, `deleteTask()`, `toggleSelesai()`.

- [ ] **Step 1: Implementasikan TaskRepository**

Create `lib/repositories/task_repository.dart`:
```dart
import 'package:sqflite/sqflite.dart';
import '../core/services/database_service.dart';
import '../models/task_model.dart';

class TaskRepository {
  final DatabaseService _dbService;

  TaskRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  Future<int> insert(Task task) async {
    final db = await _dbService.database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Task task) async {
    final db = await _dbService.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _dbService.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'waktu_pengingat ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getPendingTasks() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'selesai = 0',
      orderBy: 'waktu_pengingat ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }
}
```

- [ ] **Step 2: Tulis test logika TaskController (pemisahan Mendesak vs Berikutnya)**

Create `test/controllers/task_controller_test.dart`:
```dart
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

      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final isUrgent1 = !todayUrgent.selesai && !todayUrgent.waktuPengingat.isAfter(endOfToday);
      final isUrgent2 = !tomorrowTask.selesai && !tomorrowTask.waktuPengingat.isAfter(endOfToday);
      final isUrgent3 = !completedToday.selesai && !completedToday.waktuPengingat.isAfter(endOfToday);

      expect(isUrgent1, isTrue);
      expect(isUrgent2, isFalse);
      expect(isUrgent3, isFalse);
    });
  });
}
```

- [ ] **Step 3: Jalankan test logika**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter test test/controllers/task_controller_test.dart
```
Expected: PASS.

- [ ] **Step 4: Implementasikan TaskController**

Create `lib/controllers/task_controller.dart`:
```dart
import 'package:flutter/foundation.dart';
import '../core/services/notification_service.dart';
import '../core/services/permission_service.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskController extends ChangeNotifier {
  final TaskRepository _repository;
  final NotificationService _notificationService;

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _exactAlarmPermissionGranted = true;

  TaskController({
    TaskRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? TaskRepository(),
        _notificationService = notificationService ?? NotificationService.instance;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get exactAlarmPermissionGranted => _exactAlarmPermissionGranted;

  List<Task> get mendesakTasks {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _tasks
        .where((t) => !t.selesai && !t.waktuPengingat.isAfter(endOfToday))
        .toList();
  }

  List<Task> get berikutnyaTasks {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _tasks
        .where((t) => !t.selesai && t.waktuPengingat.isAfter(endOfToday))
        .toList();
  }

  List<Task> get selesaiTasks {
    return _tasks.where((t) => t.selesai).toList();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    _exactAlarmPermissionGranted = await PermissionService.isExactAlarmGranted();
    _tasks = await _repository.getAllTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _exactAlarmPermissionGranted = await PermissionService.isExactAlarmGranted();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _repository.insert(task);
    if (!task.selesai) {
      await _notificationService.scheduleTask(task);
    }
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _repository.update(task);
    if (task.selesai) {
      await _notificationService.cancelTask(task.notificationId);
    } else {
      await _notificationService.scheduleTask(task);
    }
    await loadTasks();
  }

  Future<void> toggleSelesai(Task task) async {
    final updated = task.copyWith(selesai: !task.selesai);
    await updateTask(updated);
  }

  Future<void> deleteTask(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      await _notificationService.cancelTask(task.notificationId);
    }
    await _repository.delete(id);
    await loadTasks();
  }

  Future<void> rescheduleAllPending() async {
    final pending = await _repository.getPendingTasks();
    for (final task in pending) {
      await _notificationService.scheduleTask(task);
    }
  }
}
```

- [ ] **Step 5: Verifikasi static analysis**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter analyze
```
Expected: 0 errors.

---

### Task 5: Tema, Warna & UI Layar Utama (HomeScreen)

**Files:**
- Create: `lib/core/constants/app_colors.dart`
- Create: `lib/core/constants/app_theme.dart`
- Create: `lib/views/home/widgets/task_card.dart`
- Create: `lib/views/home/widgets/summary_header.dart`
- Create: `lib/views/home/widgets/permission_banner.dart`
- Create: `lib/views/home/widgets/empty_state.dart`
- Create: `lib/views/home/home_screen.dart`

**Interfaces:**
- Consumes: `TaskController`, `Task`, `AppColors`, `AppTheme`.
- Produces: Dark masculine UI home screen with summary header, Mendesak list, Berikutnya list, card with circular checkbox, edit/delete actions, and FAB.

- [ ] **Step 1: Buat AppColors & AppTheme**

Create `lib/core/constants/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF282828);
  static const Color border = Color(0xFF2C2C2C);
  static const Color amber = Color(0xFFFF9800);
  static const Color amberDark = Color(0xFFE65100);
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF4A4A4A);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
}
```

Create `lib/core/constants/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amber,
        onPrimary: Colors.black,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Buat SummaryHeader & PermissionBanner**

Create `lib/views/home/widgets/summary_header.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SummaryHeader extends StatelessWidget {
  final int urgentCount;

  const SummaryHeader({super.key, required this.urgentCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Halo,',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Kamu memiliki '),
                TextSpan(
                  text: '$urgentCount tugas mendesak',
                  style: const TextStyle(color: AppColors.amber),
                ),
                const TextSpan(text: ' hari ini'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/views/home/widgets/permission_banner.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/permission_service.dart';

class PermissionBanner extends StatelessWidget {
  final VoidCallback onRefresh;

  const PermissionBanner({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1C0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.parseBorder('1px solid #FF9800') != null
            ? Border.all(color: AppColors.amber.withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Izin alarm tepat waktu nonaktif. Pengingat bisa terlambat.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () async {
              await PermissionService.openSettings();
              onRefresh();
            },
            child: const Text(
              'Pengaturan',
              style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Buat EmptyState & TaskCard**

Create `lib/views/home/widgets/empty_state.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const EmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Belum ada pengingat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadwalkan tugas Anda agar tidak ada yang terlewat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Tambah Pengingat',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Create `lib/views/home/widgets/task_card.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isDimmed;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.isDimmed = false,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('dd MMM HH:mm', 'id_ID');
    final formattedTime = timeFormat.format(task.waktuPengingat);

    return Opacity(
      opacity: isDimmed ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.selesai ? AppColors.amber : Colors.transparent,
                        border: Border.all(
                          color: task.selesai ? AppColors.amber : AppColors.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: task.selesai
                          ? const Icon(Icons.check, size: 16, color: Colors.black)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.judul,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: task.selesai
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 13, color: AppColors.amber),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (task.ulangi != 'tidak') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.ulangi == 'harian' ? 'Harian' : 'Mingguan',
                                  style: const TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementasikan HomeScreen**

Create `lib/views/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../form/task_form_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/permission_banner.dart';
import 'widgets/summary_header.dart';
import 'widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  final TaskController controller;

  const HomeScreen({super.key, required this.controller});

  void _openForm(BuildContext context, [Task? task]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(controller: controller, task: task),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Pengingat', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Yakin ingin menghapus pengingat "${task.judul}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteTask(task.id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
          );
        }

        final mendesak = controller.mendesakTasks;
        final berikutnya = controller.berikutnyaTasks;
        final isEmpty = controller.tasks.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengingat'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () => controller.loadTasks(),
              ),
            ],
          ),
          body: isEmpty
              ? EmptyState(onAdd: () => _openForm(context))
              : RefreshIndicator(
                  color: AppColors.amber,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => controller.loadTasks(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      SummaryHeader(urgentCount: mendesak.length),
                      if (!controller.exactAlarmPermissionGranted)
                        PermissionBanner(
                          onRefresh: () => controller.checkPermissions(),
                        ),
                      if (mendesak.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Text(
                            'MENDESAK',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...mendesak.map((task) => TaskCard(
                              task: task,
                              onToggle: () => controller.toggleSelesai(task),
                              onTap: () => _openForm(context, task),
                              onDelete: () => _confirmDelete(context, task),
                            )),
                      ],
                      if (berikutnya.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'BERIKUTNYA',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...berikutnya.map((task) => TaskCard(
                              task: task,
                              isDimmed: true,
                              onToggle: () => controller.toggleSelesai(task),
                              onTap: () => _openForm(context, task),
                              onDelete: () => _confirmDelete(context, task),
                            )),
                      ],
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openForm(context),
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Verifikasi static analysis**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter analyze
```
Expected: 0 errors.

---

### Task 6: UI Layar Form Pengingat (TaskFormScreen)

**Files:**
- Create: `lib/views/form/task_form_screen.dart`

**Interfaces:**
- Consumes: `Task`, `TaskController`, `AppColors`.
- Produces: `TaskFormScreen` with title input, notes input, 2-column Date/Time pickers, recurrence dropdown, save validation, and full-width amber button.

- [ ] **Step 1: Implementasikan TaskFormScreen**

Create `lib/views/form/task_form_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/task_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskController controller;
  final Task? task;

  const TaskFormScreen({super.key, required this.controller, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _catatanController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedUlangi;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _judulController = TextEditingController(text: task?.judul ?? '');
    _catatanController = TextEditingController(text: task?.catatan ?? '');

    if (task != null) {
      _selectedDate = task.waktuPengingat;
      _selectedTime = TimeOfDay.fromDateTime(task.waktuPengingat);
      _selectedUlangi = task.ulangi;
    } else {
      final now = DateTime.now().add(const Duration(hours: 1));
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _selectedUlangi = 'tidak';
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.amber,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.amber,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveTask() {
    final judul = _judulController.text.trim();
    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tugas tidak boleh kosong'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (_selectedUlangi == 'tidak' && combinedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu pengingat harus berada di masa mendatang'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final now = DateTime.now();
    if (isEdit) {
      final updated = widget.task!.copyWith(
        judul: judul,
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
        waktuPengingat: combinedDateTime,
        ulangi: _selectedUlangi,
      );
      widget.controller.updateTask(updated);
    } else {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        judul: judul,
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
        waktuPengingat: combinedDateTime,
        ulangi: _selectedUlangi,
        selesai: false,
        dibuatPada: now,
      );
      widget.controller.addTask(newTask);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final formattedDate = dateFormat.format(_selectedDate);
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Pengingat' : 'Tugas Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Judul Tugas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'cth: Bayar listrik',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.amber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Catatan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'opsional',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.amber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: AppColors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: AppColors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Ulangi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUlangi,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'tidak', child: Text('Tidak')),
                      DropdownMenuItem(value: 'harian', child: Text('Harian')),
                      DropdownMenuItem(value: 'mingguan', child: Text('Mingguan')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUlangi = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Pengingat',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verifikasi static analysis**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter analyze
```
Expected: 0 errors.

---

### Task 7: Integrasi main.dart, Reschedule Otomatis & Polish

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `intl/date_symbol_data_local.dart`, `NotificationService`, `PermissionService`, `TaskController`, `HomeScreen`, `AppTheme`.
- Produces: App entry point initializing timezone, date formatting `id_ID`, requesting notification permission on launch, rescheduling pending tasks, and rendering `HomeScreen`.

- [ ] **Step 1: Implementasikan main.dart**

Create / replace `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/task_controller.dart';
import 'core/constants/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/permission_service.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Notifikasi & Timezone
  await NotificationService.instance.initialize();

  // Minta izin notifikasi (Android 13+)
  await PermissionService.requestNotificationPermission();

  final taskController = TaskController();
  await taskController.loadTasks();

  // Reschedule semua pending tasks untuk resiliensi setelah reboot
  await taskController.rescheduleAllPending();

  runApp(PengingatApp(controller: taskController));
}

class PengingatApp extends StatelessWidget {
  final TaskController controller;

  const PengingatApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengingat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(controller: controller),
    );
  }
}
```

- [ ] **Step 2: Jalankan seluruh unit test**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter test
```
Expected: 100% test passing.

- [ ] **Step 3: Jalankan static analysis komprehensif**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter analyze
```
Expected: 0 errors, 0 warnings.

---

### Task 8: Build APK Release (Fase B)

**Files:**
- Generates: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Generates: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- Generates: `build/app/outputs/flutter-apk/app-x86_64-release.apk`

- [ ] **Step 1: Eksekusi build release split-ABI dengan obfuscation**

Run:
```bash
cd C:/Users/NAN/Desktop/pengingat
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
```
Expected: Build sukses menghasilkan APK split-ABI di `build/app/outputs/flutter-apk/`.

- [ ] **Step 2: Verifikasi ukuran file APK dan metadata permissions**

Run:
```bash
ls -lh C:/Users/NAN/Desktop/pengingat/build/app/outputs/flutter-apk/*.apk
```
Expected: File APK tersedia dan valid.
