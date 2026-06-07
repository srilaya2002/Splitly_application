import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _memberCtrl = TextEditingController();
  String _currency = 'GBP';
  final List<ProfileModel> _members = [];
  bool _loading = false;

  Future<void> _addMember() async {
    final id = _memberCtrl.text.trim().toUpperCase();
    if (!id.startsWith('SPL-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Spltly ID (SPL-XXXXXX)')));
      return;
    }
    if (_members.any((m) => m.spltlyId == id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already added')));
      return;
    }
    final profile = await SupabaseService.getProfileBySpltlyId(id);
    if (profile == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with that ID')));
      return;
    }
    setState(() { _members.add(profile); _memberCtrl.clear(); });
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.createGroup(
        name: _nameCtrl.text.trim(),
        currency: _currency,
        memberIds: _members.map((m) => m.id).toList(),
      );
      if (mounted) context.go('/groups');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMuted, size: 18),
          onPressed: () => context.go('/groups'),
        ),
        title: const Text('Create group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(controller: _nameCtrl, label: 'Group name', hint: 'Barcelona Trip'),
                  const SizedBox(height: 16),
                  const Text('Currency', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButton<String>(
                      value: _currency,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: AppTheme.bg2,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      items: ['GBP', 'EUR', 'USD', 'INR'].map((c) =>
                          DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add members by Spltly ID',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _memberCtrl,
                    label: '',
                    hint: 'SPL-XXXXXX',
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addMember,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.glass2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border2),
                    ),
                    child: const Text('Add', style: TextStyle(color: AppTheme.purple2, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            if (_members.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _members.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.displayName, style: const TextStyle(color: AppTheme.green, fontSize: 13)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _members.remove(m)),
                        child: const Icon(Icons.close, color: AppTheme.green, size: 14),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(label: 'Create group', loading: _loading, onPressed: _create),
          ],
        ),
      ),
    );
  }
}
