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
        title: const Text('Hapus Pengingat',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Yakin ingin menghapus pengingat "${task.judul}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteTask(task.id);
            },
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.error)),
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
                icon: const Icon(Icons.refresh,
                    color: AppColors.textSecondary),
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
