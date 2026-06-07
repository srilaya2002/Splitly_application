import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/ambient_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ProfileModel? _profile;
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await SupabaseService.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = p;
          _nameCtrl.text = p?.displayName ?? '';
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.updateProfile(displayName: _nameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated ✓')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copyId() {
    if (_profile == null) return;
    Clipboard.setData(ClipboardData(text: _profile!.spltlyId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spltly ID copied ✓')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AmbientBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.purple))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppTheme.purple, AppTheme.teal]),
                              ),
                              child: Center(child: Text(
                                _profile?.initials ?? '?',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                              )),
                            ),
                            const SizedBox(height: 12),
                            Text(_profile?.displayName ?? '',
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(_profile?.email ?? '',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.teal.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Your Spltly ID', style: TextStyle(color: AppTheme.textFaint, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(_profile?.spltlyId ?? '',
                                          style: const TextStyle(color: AppTheme.teal, fontSize: 20,
                                              fontWeight: FontWeight.w600, letterSpacing: 1, fontFamily: 'monospace')),
                                    ],
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _copyId,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.teal.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Copy', style: TextStyle(color: AppTheme.teal, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Share this ID so others can add you to groups without your phone number.',
                                style: TextStyle(color: AppTheme.textFaint, fontSize: 11), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Edit profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 16),
                            AppTextField(controller: _nameCtrl, label: 'Display name', hint: 'Your name'),
                            const SizedBox(height: 16),
                            AppButton(label: 'Save changes', loading: _saving, onPressed: _save),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          await SupabaseService.signOut();
                          if (mounted) context.go('/auth/login');
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: const Row(
                            children: [
                              Icon(Icons.logout, color: AppTheme.red, size: 20),
                              SizedBox(width: 12),
                              Text('Sign out', style: TextStyle(color: AppTheme.red, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
