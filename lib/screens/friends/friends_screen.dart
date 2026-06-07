import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/ambient_background.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  ProfileModel? _foundProfile;
  bool _searching = false;
  String? _searchError;

  Future<void> _search() async {
    final id = _searchCtrl.text.trim().toUpperCase();
    if (!id.startsWith('SPL-')) {
      setState(() => _searchError = 'Enter a valid Spltly ID (SPL-XXXXXX)');
      return;
    }
    setState(() { _searching = true; _searchError = null; _foundProfile = null; });
    final profile = await SupabaseService.getProfileBySpltlyId(id);
    if (mounted) {
      setState(() {
        _searching = false;
        _foundProfile = profile;
        if (profile == null) _searchError = 'No user found with that ID';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Friends', style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Find anyone by their Spltly ID — no phone needed',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Search by Spltly ID',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _searchCtrl,
                              label: '',
                              hint: 'SPL-XXXXXX',
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _search,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _searching
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.search, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      if (_searchError != null) ...[
                        const SizedBox(height: 8),
                        Text(_searchError!, style: const TextStyle(color: AppTheme.red, fontSize: 12)),
                      ],
                      if (_foundProfile != null) ...[
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppTheme.purple, AppTheme.teal]),
                              ),
                              child: Center(child: Text(_foundProfile!.initials,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_foundProfile!.displayName,
                                      style: const TextStyle(color: AppTheme.textPrimary,
                                          fontSize: 15, fontWeight: FontWeight.w500)),
                                  Text(_foundProfile!.spltlyId,
                                      style: const TextStyle(color: AppTheme.teal,
                                          fontSize: 12, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                              ),
                              child: const Text('Found ✓',
                                  style: TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline, color: AppTheme.purple, size: 16),
                        SizedBox(width: 8),
                        Text('How Spltly IDs work',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ]),
                      SizedBox(height: 12),
                      Text(
                        'Every user gets a unique ID like SPL-482193 on signup. Share yours so friends can add you to groups without needing your phone number.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
