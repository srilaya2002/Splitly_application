// ─── Profile Model ───
class ProfileModel {
  final String id;
  final String displayName;
  final String spltlyId;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.displayName,
    required this.spltlyId,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      displayName: map['display_name'] ?? '',
      spltlyId: map['spltly_id'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'display_name': displayName,
    'spltly_id': spltlyId,
    'email': email,
    'avatar_url': avatarUrl,
  };

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}

// ─── Group Model ───
class GroupModel {
  final String id;
  final String name;
  final String createdBy;
  final String currency;
  final DateTime createdAt;
  List<GroupMemberModel> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.currency,
    required this.createdAt,
    this.members = const [],
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'],
      createdBy: map['created_by'],
      currency: map['currency'] ?? 'GBP',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'created_by': createdBy,
    'currency': currency,
  };
}

// ─── Group Member Model ───
class GroupMemberModel {
  final String id;
  final String groupId;
  final String userId;
  final DateTime joinedAt;
  ProfileModel? profile;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    this.profile,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id'],
      groupId: map['group_id'],
      userId: map['user_id'],
      joinedAt: DateTime.parse(map['joined_at']),
      profile: map['profiles'] != null
          ? ProfileModel.fromMap(map['profiles'])
          : null,
    );
  }
}

// ─── Expense Model ───
class ExpenseModel {
  final String id;
  final String groupId;
  final String paidBy;
  final String description;
  final double amount;
  final String splitType;
  final String? receiptUrl;
  final String? note;
  final DateTime createdAt;
  ProfileModel? paidByProfile;
  List<ExpenseSplitModel> splits;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.description,
    required this.amount,
    required this.splitType,
    this.receiptUrl,
    this.note,
    required this.createdAt,
    this.paidByProfile,
    this.splits = const [],
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      groupId: map['group_id'],
      paidBy: map['paid_by'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      splitType: map['split_type'] ?? 'equal',
      receiptUrl: map['receipt_url'],
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
      paidByProfile: map['profiles'] != null
          ? ProfileModel.fromMap(map['profiles'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'group_id': groupId,
    'paid_by': paidBy,
    'description': description,
    'amount': amount,
    'split_type': splitType,
    'receipt_url': receiptUrl,
    'note': note,
  };
}

// ─── Expense Split Model ───
class ExpenseSplitModel {
  final String id;
  final String expenseId;
  final String userId;
  final double amountOwed;
  final bool settled;
  final DateTime? settledAt;
  ProfileModel? profile;

  ExpenseSplitModel({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amountOwed,
    required this.settled,
    this.settledAt,
    this.profile,
  });

  factory ExpenseSplitModel.fromMap(Map<String, dynamic> map) {
    return ExpenseSplitModel(
      id: map['id'],
      expenseId: map['expense_id'],
      userId: map['user_id'],
      amountOwed: (map['amount_owed'] as num).toDouble(),
      settled: map['settled'] ?? false,
      settledAt: map['settled_at'] != null
          ? DateTime.parse(map['settled_at'])
          : null,
      profile: map['profiles'] != null
          ? ProfileModel.fromMap(map['profiles'])
          : null,
    );
  }
}

// ─── Balance Model ───
class BalanceModel {
  final String userId;
  final String userName;
  final String userInitials;
  final double amount; // positive = they owe you, negative = you owe them

  BalanceModel({
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.amount,
  });
}
