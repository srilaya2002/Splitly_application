import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ambient_background.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  ExpenseModel? _expense;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await SupabaseService.getAllMyExpenses();
      final exp = all.where((e) => e.id == widget.expenseId).firstOrNull;
      if (mounted) setState(() { _expense = exp; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _settle(ExpenseSplitModel split) async {
    try {
      await SupabaseService.settleUp(splitId: split.id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as settled ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMuted, size: 18),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Expense detail'),
        actions: [
          if (_expense?.paidBy == SupabaseService.currentUserId)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 22),
              onPressed: () async {
                await SupabaseService.deleteExpense(widget.expenseId);
                if (mounted) context.go('/');
              },
            ),
        ],
      ),
      body: AmbientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.purple))
            : _expense == null
                ? const Center(child: Text('Expense not found', style: TextStyle(color: AppTheme.textMuted)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_expense!.description,
                                  style: const TextStyle(color: AppTheme.textPrimary,
                                      fontSize: 20, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(fmt.format(_expense!.amount),
                                  style: const TextStyle(color: AppTheme.purple2,
                                      fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.person_outline, color: AppTheme.textFaint, size: 14),
                                const SizedBox(width: 6),
                                Text('Paid by ${_expense!.paidByProfile?.displayName ?? 'Unknown'}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                const Spacer(),
                                Text(DateFormat('MMM d, y').format(_expense!.createdAt),
                                    style: const TextStyle(color: AppTheme.textFaint, fontSize: 12)),
                              ]),
                              if (_expense!.note != null) ...[
                                const SizedBox(height: 8),
                                Text(_expense!.note!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              ],
                              if (_expense!.receiptUrl != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
                                  ),
                                  child: const Row(children: [
                                    Icon(Icons.attach_file, color: AppTheme.teal, size: 14),
                                    SizedBox(width: 6),
                                    Text('Receipt attached', style: TextStyle(color: AppTheme.teal, fontSize: 12)),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Splits', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.8)),
                        const SizedBox(height: 10),
                        ..._expense!.splits.map((split) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: split.settled
                                        ? AppTheme.green.withOpacity(0.15)
                                        : AppTheme.red.withOpacity(0.15),
                                  ),
                                  child: Center(child: Text(
                                    split.profile?.initials ?? '?',
                                    style: TextStyle(
                                      color: split.settled ? AppTheme.green : AppTheme.red,
                                      fontWeight: FontWeight.w600, fontSize: 12,
                                    ),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(split.profile?.displayName ?? 'Member',
                                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                    Text(split.settled ? 'Settled' : 'Pending',
                                        style: TextStyle(
                                          color: split.settled ? AppTheme.green : AppTheme.red,
                                          fontSize: 11,
                                        )),
                                  ],
                                )),
                                Text(fmt.format(split.amountOwed),
                                    style: const TextStyle(color: AppTheme.textPrimary,
                                        fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                                if (!split.settled && split.userId == SupabaseService.currentUserId) ...[
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _settle(split),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                                      ),
                                      child: const Text('Settle',
                                          style: TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }
}
