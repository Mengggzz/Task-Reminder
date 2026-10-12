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
