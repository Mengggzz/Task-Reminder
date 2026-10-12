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
        _notificationService =
            notificationService ?? NotificationService.instance;

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

    _exactAlarmPermissionGranted =
        await PermissionService.isExactAlarmGranted();
    _tasks = await _repository.getAllTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _exactAlarmPermissionGranted =
        await PermissionService.isExactAlarmGranted();
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
