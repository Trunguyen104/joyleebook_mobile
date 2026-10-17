import 'package:flutter/material.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_colors.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_dimensions.dart';

class ReadingStatTile extends StatelessWidget {
  const ReadingStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; // theme darkmode lightmode

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colors.primaryBrand),
            const SizedBox(height: AppDimensions.space2),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis, // nhãn dài thì thành "..."
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
