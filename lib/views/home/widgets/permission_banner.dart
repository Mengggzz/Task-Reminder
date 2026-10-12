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
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.amber, size: 24),
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
              style: TextStyle(
                  color: AppColors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
