import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Dashboard "Top Cards" tile - Total Rooms, Available, Today's Revenue...
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) Icon(icon, color: accent, size: 22),
              const SizedBox(height: 8),
              Text(value, style: AppTextStyles.statValue),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
      ),
    );
  }
}
