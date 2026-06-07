import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;
  static User? get currentUser => _client.auth.currentUser;
  static String get currentUserId => _client.auth.currentUser!.id;

  // ─── AUTH ───

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ─── PROFILE ───

  static Future<ProfileModel?> getMyProfile() async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .single();
    return ProfileModel.fromMap(res);
  }

  static Future<ProfileModel?> getProfileBySpltlyId(String spltlyId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('spltly_id', spltlyId.toUpperCase())
          .single();
      return ProfileModel.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    await _client.from('profiles').update({
      'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', currentUserId);
  }

  static Future<String?> uploadAvatar(File file) async {
    final ext = file.path.split('.').last;
    final path = '${currentUserId}/avatar.$ext';
    await _client.storage.from('avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  // ─── GROUPS ───

  static Future<List<GroupModel>> getMyGroups() async {
    final res = await _client
        .from('groups')
        .select('''
          *,
          group_members!inner(
            *,
            profiles(id, display_name, spltly_id, avatar_url)
          )
        ''')
        .eq('group_members.user_id', currentUserId)
        .order('created_at', ascending: false);

    return (res as List).map((g) {
      final group = GroupModel.fromMap(g);
      group.members = (g['group_members'] as List)
          .map((m) => GroupMemberModel.fromMap(m))
          .toList();
      return group;
    }).toList();
  }

  static Future<GroupModel> createGroup({
    required String name,
    required String currency,
    required List<String> memberIds,
  }) async {
    // Create group
    final groupRes = await _client.from('groups').insert({
      'name': name,
      'created_by': currentUserId,
      'currency': currency,
    }).select().single();

    final group = GroupModel.fromMap(groupRes);

    // Add creator as member
    final allMemberIds = [currentUserId, ...memberIds];
    await _client.from('group_members').insert(
      allMemberIds.map((id) => {
        'group_id': group.id,
        'user_id': id,
      }).toList(),
    );

    return group;
  }

  static Future<void> addMemberToGroup({
    required String groupId,
    required String userId,
  }) async {
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });
  }

  static Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
  }

  // ─── EXPENSES ───

  static Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final res = await _client
        .from('expenses')
        .select('''
          *,
          profiles!paid_by(id, display_name, spltly_id, avatar_url),
          expense_splits(
            *,
            profiles(id, display_name, spltly_id, avatar_url)
          )
        ''')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (res as List).map((e) {
      final expense = ExpenseModel.fromMap(e);
      expense.splits = (e['expense_splits'] as List)
          .map((s) => ExpenseSplitModel.fromMap(s))
          .toList();
      return expense;
    }).toList();
  }

  static Future<List<ExpenseModel>> getAllMyExpenses() async {
    final groupIds = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', currentUserId);

    if ((groupIds as List).isEmpty) return [];

    final ids = groupIds.map((g) => g['group_id'] as String).toList();

    final res = await _client
        .from('expenses')
        .select('''
          *,
          profiles!paid_by(id, display_name, spltly_id, avatar_url),
          expense_splits!inner(
            *,
            profiles(id, display_name, spltly_id, avatar_url)
          )
        ''')
        .inFilter('group_id', ids)
        .order('created_at', ascending: false);

    return (res as List).map((e) {
      final expense = ExpenseModel.fromMap(e);
      expense.splits = (e['expense_splits'] as List)
          .map((s) => ExpenseSplitModel.fromMap(s))
          .toList();
      return expense;
    }).toList();
  }

  static Future<ExpenseModel> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String splitType,
    required List<Map<String, dynamic>> splits,
    String? receiptUrl,
    String? note,
  }) async {
    // Insert expense
    final expRes = await _client.from('expenses').insert({
      'group_id': groupId,
      'paid_by': currentUserId,
      'description': description,
      'amount': amount,
      'split_type': splitType,
      'receipt_url': receiptUrl,
      'note': note,
    }).select().single();

    final expense = ExpenseModel.fromMap(expRes);

    // Insert splits
    await _client.from('expense_splits').insert(
      splits.map((s) => {
        'expense_id': expense.id,
        'user_id': s['user_id'],
        'amount_owed': s['amount_owed'],
      }).toList(),
    );

    return expense;
  }

  static Future<String?> uploadReceipt(File file, String expenseId) async {
    final ext = file.path.split('.').last;
    final path = 'expenses/$expenseId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('receipts').upload(path, file);
    return _client.storage.from('receipts').getPublicUrl(path);
  }

  static Future<void> settleUp({
    required String splitId,
  }) async {
    await _client.from('expense_splits').update({
      'settled': true,
      'settled_at': DateTime.now().toIso8601String(),
    }).eq('id', splitId).eq('user_id', currentUserId);
  }

  static Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  // ─── BALANCES ───

  static Future<Map<String, double>> getGroupBalances(String groupId) async {
    final expenses = await getGroupExpenses(groupId);
    final balances = <String, double>{};

    for (final expense in expenses) {
      for (final split in expense.splits) {
        if (split.settled) continue;
        if (split.userId == currentUserId && expense.paidBy != currentUserId) {
          // I owe this person
          balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) - split.amountOwed;
        } else if (expense.paidBy == currentUserId && split.userId != currentUserId) {
          // They owe me
          balances[split.userId] = (balances[split.userId] ?? 0) + split.amountOwed;
        }
      }
    }

    return balances;
  }

  static Future<double> getTotalOwed() async {
    final expenses = await getAllMyExpenses();
    double total = 0;
    for (final expense in expenses) {
      for (final split in expense.splits) {
        if (split.settled) continue;
        if (split.userId == currentUserId && expense.paidBy != currentUserId) {
          total += split.amountOwed;
        }
      }
    }
    return total;
  }

  static Future<double> getTotalOwedToMe() async {
    final expenses = await getAllMyExpenses();
    double total = 0;
    for (final expense in expenses) {
      if (expense.paidBy != currentUserId) continue;
      for (final split in expense.splits) {
        if (split.settled) continue;
        if (split.userId != currentUserId) {
          total += split.amountOwed;
        }
      }
    }
    return total;
  }
}
