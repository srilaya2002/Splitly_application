import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/expense_item_widget.dart';
import '../../widgets/group_card_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ProfileModel? _profile;
  List<GroupModel> _groups = [];
  List<ExpenseModel> _expenses = [];
  double _totalOwed = 0;
  double _totalOwedToMe = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getMyProfile(),
        SupabaseService.getMyGroups(),
        SupabaseService.getAllMyExpenses(),
        SupabaseService.getTotalOwed(),
        SupabaseService.getTotalOwedToMe(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as ProfileModel?;
          _groups = results[1] as List<GroupModel>;
          _expenses = results[2] as List<ExpenseModel>;
          _totalOwed = results[3] as double;
          _totalOwedToMe = results[4] as double;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);
    final net = _totalOwedToMe - _totalOwed;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AmbientBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.purple,
          backgroundColor: AppTheme.bg2,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                floating: true,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _greeting,
                                style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 14),
                              ),
                              Text(
                                _profile?.displayName.split(' ').first ?? 'there',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        GestureDetector(
                          onTap: () => context.go('/settings'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.purple, AppTheme.teal],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _profile?.initials ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.purple),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'You are owed',
                              value: fmt.format(_totalOwedToMe),
                              color: AppTheme.green,
                              topColor: AppTheme.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'You owe',
                              value: fmt.format(_totalOwed),
                              color: AppTheme.red,
                              topColor: AppTheme.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        label: 'Net balance',
                        value: '${net >= 0 ? '+' : ''}${fmt.format(net)}',
                        color: net >= 0 ? AppTheme.green : AppTheme.red,
                        topColor: AppTheme.purple,
                        wide: true,
                      ),

                      const SizedBox(height: 28),

                      // Groups
                      Row(
                        children: [
                          const Text('Your groups',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go('/groups'),
                            child: const Text('See all',
                                style: TextStyle(color: AppTheme.purple2, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_groups.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.group_outlined,
                                    color: AppTheme.textFaint, size: 32),
                                const SizedBox(height: 8),
                                const Text('No groups yet',
                                    style: TextStyle(color: AppTheme.textMuted)),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => context.go('/groups/create'),
                                  child: const Text('Create a group',
                                      style: TextStyle(color: AppTheme.purple2)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _groups.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => GroupCardWidget(
                              group: _groups[i],
                              onTap: () => context.go('/groups/${_groups[i].id}'),
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Recent expenses
                      Row(
                        children: [
                          const Text('Recent expenses',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go('/expenses/add'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.purple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('+ Add',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_expenses.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: const Center(
                            child: Text('No expenses yet',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ),
                        )
                      else
                        ..._expenses.take(5).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ExpenseItemWidget(
                            expense: e,
                            onTap: () => context.go('/expenses/${e.id}'),
                          ),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color topColor;
  final bool wide;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.topColor,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: topColor,
          )),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: wide ? 24 : 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              )),
        ],
      ),
    );
  }
}
