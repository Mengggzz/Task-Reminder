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
