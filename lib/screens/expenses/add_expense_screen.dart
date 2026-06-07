import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/ambient_background.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? groupId;
  const AddExpenseScreen({super.key, this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  String _splitType = 'equal';
  File? _receiptFile;
  bool _loading = false;
  bool _loadingGroups = true;

  // members and their split amounts
  List<Map<String, dynamic>> _splitMembers = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _amtCtrl.addListener(_updateSplits);
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await SupabaseService.getMyGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _loadingGroups = false;
          if (widget.groupId != null) {
            _selectedGroup = groups.firstWhere(
                (g) => g.id == widget.groupId, orElse: () => groups.first);
          } else if (groups.isNotEmpty) {
            _selectedGroup = groups.first;
          }
          _buildSplitMembers();
        });
      }
    } catch (_) { if (mounted) setState(() => _loadingGroups = false); }
  }

  void _buildSplitMembers() {
    if (_selectedGroup == null) return;
    _splitMembers = _selectedGroup!.members.map((m) => {
      'user_id': m.userId,
      'name': m.profile?.displayName ?? 'Member',
      'initials': m.profile?.initials ?? '?',
      'amount_owed': 0.0,
    }).toList();
    _updateSplits();
  }

  void _updateSplits() {
    if (_splitType != 'equal') return;
    final amt = double.tryParse(_amtCtrl.text) ?? 0;
    final count = _splitMembers.length;
    if (count == 0) return;
    final per = double.parse((amt / count).toStringAsFixed(2));
    setState(() {
      for (var m in _splitMembers) { m['amount_owed'] = per; }
    });
  }

  Future<void> _pickReceipt() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.purple),
              title: const Text('Take photo', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final img = await ImagePicker().pickImage(source: ImageSource.camera);
                if (img != null) setState(() => _receiptFile = File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.purple),
              title: const Text('Choose from library', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (img != null) setState(() => _receiptFile = File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppTheme.purple),
              title: const Text('Choose file (PDF)', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(type: FileType.any);
                if (result != null) setState(() => _receiptFile = File(result.files.single.path!));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a description')));
      return;
    }
    final amt = double.tryParse(_amtCtrl.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a group')));
      return;
    }
    setState(() => _loading = true);
    try {
      // Upload receipt if attached
      String? receiptUrl;
      if (_receiptFile != null) {
        final expId = DateTime.now().millisecondsSinceEpoch.toString();
        receiptUrl = await SupabaseService.uploadReceipt(_receiptFile!, expId);
      }

      await SupabaseService.addExpense(
        groupId: _selectedGroup!.id,
        description: _descCtrl.text.trim(),
        amount: amt,
        splitType: _splitType,
        splits: _splitMembers.map((m) => {
          'user_id': m['user_id'],
          'amount_owed': m['amount_owed'],
        }).toList(),
        receiptUrl: receiptUrl,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added ✓')));
        if (widget.groupId != null) {
          context.go('/groups/${widget.groupId}');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMuted, size: 18),
          onPressed: () => context.go(widget.groupId != null ? '/groups/${widget.groupId}' : '/'),
        ),
        title: const Text('Add expense'),
      ),
      body: _loadingGroups
          ? const Center(child: CircularProgressIndicator(color: AppTheme.purple))
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
                  AppTextField(
                    controller: _descCtrl,
                    label: 'Description',
                    hint: 'Dinner at Dishoom',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _amtCtrl,
                    label: 'Amount',
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: Text(
                      _selectedGroup?.currency == 'GBP' ? '£' :
                      _selectedGroup?.currency == 'EUR' ? '€' :
                      _selectedGroup?.currency == 'USD' ? '\$' : '₹',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Group selector
                  const Text('Group', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButton<GroupModel>(
                      value: _selectedGroup,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: AppTheme.bg2,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      items: _groups.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.name),
                      )).toList(),
                      onChanged: (g) {
                        setState(() {
                          _selectedGroup = g;
                          _buildSplitMembers();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Split type
                  const Text('Split type', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['equal', 'exact', 'percent'].map((type) {
                      final selected = _splitType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _splitType = type;
                            if (type == 'equal') _updateSplits();
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.purple.withOpacity(0.2) : AppTheme.glass,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppTheme.purple : AppTheme.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: TextStyle(
                                  color: selected ? AppTheme.purple2 : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Split preview
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Split preview',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ..._splitMembers.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [AppTheme.purple, AppTheme.teal]),
                          ),
                          child: Center(child: Text(m['initials'],
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(m['name'],
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                        if (_splitType == 'equal')
                          Text('£${(m['amount_owed'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(color: AppTheme.teal, fontSize: 13, fontFamily: 'monospace'))
                        else
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: '0.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppTheme.teal, fontSize: 13, fontFamily: 'monospace'),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                m['amount_owed'] = double.tryParse(v) ?? 0.0;
                              },
                            ),
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Receipt upload
            GestureDetector(
              onTap: _pickReceipt,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.attach_file, color: AppTheme.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Attach receipt',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(
                            _receiptFile != null
                                ? _receiptFile!.path.split('/').last
                                : 'Optional · Photo, PDF',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_receiptFile != null)
                      GestureDetector(
                        onTap: () => setState(() => _receiptFile = null),
                        child: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                      )
                    else
                      const Icon(Icons.chevron_right, color: AppTheme.textFaint, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            GlassCard(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _noteCtrl,
                label: 'Note (optional)',
                hint: 'Any extra details...',
              ),
            ),

            const SizedBox(height: 32),
            AppButton(label: 'Add expense', loading: _loading, onPressed: _submit),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════
