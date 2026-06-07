import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class ExpenseItemWidget extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;

  const ExpenseItemWidget({super.key, required this.expense, required this.onTap});

  static const Map<String, String> _icons = {
    'food': '🍕', 'dinner': '🍽️', 'lunch': '🥪', 'coffee': '☕',
    'travel': '✈️', 'hotel': '🏨', 'airbnb': '🏠', 'uber': '🚗',
    'shop': '🛒', 'tesco': '🛒', 'amazon': '📦',
    'cinema': '🎬', 'movie': '🎬', 'ticket': '🎫',
    'petrol': '⛽', 'fuel': '⛽',
  };

  String get _icon {
    final desc = expense.description.toLowerCase();
    for (final key in _icons.keys) {
      if (desc.contains(key)) return _icons[key]!;
    }
    return '🧾';
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = SupabaseService.currentUserId;
    final mySplit = expense.splits.where((s) => s.userId == myUserId).firstOrNull;
    final iPaid = expense.paidBy == myUserId;

    String shareText;
    Color shareColor;

    if (mySplit?.settled == true) {
      shareText = 'Settled';
      shareColor = AppTheme.textMuted;
    } else if (iPaid) {
      final total = expense.splits
          .where((s) => s.userId != myUserId && !s.settled)
          .fold(0.0, (sum, s) => sum + s.amountOwed);
      shareText = total > 0 ? 'You lent £${total.toStringAsFixed(2)}' : 'You paid';
      shareColor = AppTheme.green;
    } else if (mySplit != null) {
      shareText = 'You owe £${mySplit.amountOwed.toStringAsFixed(2)}';
      shareColor = AppTheme.red;
    } else {
      shareText = '£${expense.amount.toStringAsFixed(2)}';
      shareColor = AppTheme.textMuted;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.glass2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_icon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.description,
                      style: const TextStyle(color: AppTheme.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(expense.paidByProfile?.displayName.split(' ').first ?? 'Someone',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    if (expense.receiptUrl != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.attach_file, color: AppTheme.teal, size: 11),
                    ],
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('£${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                const SizedBox(height: 2),
                Text(shareText,
                    style: TextStyle(color: shareColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
