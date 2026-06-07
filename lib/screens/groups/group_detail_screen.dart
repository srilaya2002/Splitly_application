import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/expense_item_widget.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupModel? _group;
  List<ExpenseModel> _expenses = [];
  Map<String, double> _balances = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getMyGroups(),
        SupabaseService.getGroupExpenses(widget.groupId),
        SupabaseService.getGroupBalances(widget.groupId),
      ]);
      final groups = results[0] as List<GroupModel>;
      if (mounted) {
        setState(() {
          try { _group = groups.firstWhere((g) => g.id == widget.groupId); } catch (_) {}
          _expenses = results[1] as List<ExpenseModel>;
          _balances = results[2] as Map<String, double>;
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AmbientBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.purple))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMuted, size: 18),
                        onPressed: () => context.go('/groups'),
                      ),
                      title: Text(_group?.name ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add, color: AppTheme.purple, size: 24),
                          onPressed: () => context.go('/expenses/add?groupId=${widget.groupId}'),
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (_balances.isNotEmpty) ...[
                            const Text('Balances', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.8)),
                            const SizedBox(height: 10),
                            ..._balances.entries.map((e) {
                              final member = _group?.members.where((m) => m.userId == e.key).firstOrNull;
                              final name = member?.profile?.displayName ?? 'Member';
                              final amt = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (amt > 0 ? AppTheme.green : AppTheme.red).withOpacity(0.15),
                                        ),
                                        child: Center(child: Text(
                                          member?.profile?.initials ?? '?',
                                          style: TextStyle(color: amt > 0 ? AppTheme.green : AppTheme.red,
                                              fontWeight: FontWeight.w600, fontSize: 12),
                                        )),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
                                      Text(
                                        amt > 0 ? 'owes you £${amt.toStringAsFixed(2)}' : 'you owe £${amt.abs().toStringAsFixed(2)}',
                                        style: TextStyle(color: amt > 0 ? AppTheme.green : AppTheme.red, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                          const Text('Expenses', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          if (_expenses.isEmpty)
                            GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(children: [
                                  const Icon(Icons.receipt_long_outlined, color: AppTheme.textFaint, size: 32),
                                  const SizedBox(height: 8),
                                  const Text('No expenses yet', style: TextStyle(color: AppTheme.textMuted)),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => context.go('/expenses/add?groupId=${widget.groupId}'),
                                    child: const Text('Add first expense', style: TextStyle(color: AppTheme.purple2)),
                                  ),
                                ]),
                              ),
                            )
                          else
                            ..._expenses.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ExpenseItemWidget(expense: e, onTap: () => context.go('/expenses/${e.id}')),
                            )),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
