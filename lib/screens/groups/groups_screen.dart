import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/group_card_widget.dart';
import '../../widgets/glass_card.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<GroupModel> _groups = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final groups = await SupabaseService.getMyGroups();
      if (mounted) setState(() { _groups = groups; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text('Groups', style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/groups/create'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.purple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('+ New', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.purple))
                    : _groups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group_outlined, color: AppTheme.textFaint, size: 48),
                                const SizedBox(height: 12),
                                const Text('No groups yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.go('/groups/create'),
                                  child: const Text('Create your first group'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppTheme.purple,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _groups.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => GroupCardWidget(
                                group: _groups[i],
                                onTap: () => context.go('/groups/${_groups[i].id}'),
                                fullWidth: true,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
