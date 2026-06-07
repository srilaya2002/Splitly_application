import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class GroupCardWidget extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final bool fullWidth;

  const GroupCardWidget({
    super.key,
    required this.group,
    required this.onTap,
    this.fullWidth = false,
  });

  static const List<List<Color>> _gradients = [
    [AppTheme.purple, AppTheme.teal],
    [AppTheme.teal, AppTheme.green],
    [AppTheme.amber, AppTheme.red],
    [AppTheme.purple, AppTheme.amber],
  ];

  @override
  Widget build(BuildContext context) {
    final gradIdx = group.name.length % _gradients.length;
    final grad = _gradients[gradIdx];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: grad),
              ),
            ),
            const SizedBox(height: 12),
            Text(group.name,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${group.members.length} members',
                style: const TextStyle(color: AppTheme.textFaint, fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                ...group.members.take(3).toList().asMap().entries.map((e) {
                  final m = e.value;
                  return Container(
                    width: 24, height: 24,
                    margin: EdgeInsets.only(left: e.key > 0 ? -6 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: grad),
                      border: Border.all(color: AppTheme.bg, width: 1.5),
                    ),
                    child: Center(child: Text(
                      m.profile?.initials ?? '?',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
                    )),
                  );
                }),
                const Spacer(),
                Text(group.currency,
                    style: const TextStyle(color: AppTheme.textFaint, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
