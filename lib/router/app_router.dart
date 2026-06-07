import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/groups/group_detail_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/expenses/expense_detail_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';

      if (isSplash) return null;
      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),

      // Auth routes
      GoRoute(path: '/auth/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (c, s) => const SignupScreen()),

      // App shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/groups', builder: (c, s) => const GroupsScreen()),
          GoRoute(path: '/friends', builder: (c, s) => const FriendsScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),

      // Full screen routes
      GoRoute(
        path: '/groups/:id',
        builder: (c, s) => GroupDetailScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/create',
        builder: (c, s) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/expenses/add',
        builder: (c, s) => AddExpenseScreen(
          groupId: s.uri.queryParameters['groupId'],
        ),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (c, s) => ExpenseDetailScreen(
          expenseId: s.pathParameters['id']!,
        ),
      ),
    ],
  );
});
