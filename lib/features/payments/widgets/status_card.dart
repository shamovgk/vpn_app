import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';

class StatusCard extends StatelessWidget {
  final String statusText;
  final String periodText;
  final Color statusColor;

  const StatusCard({
    super.key,
    required this.statusText,
    required this.periodText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      color: colors.bgLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(height: 10),
            Text(periodText, style: TextStyle(fontSize: 16, color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
