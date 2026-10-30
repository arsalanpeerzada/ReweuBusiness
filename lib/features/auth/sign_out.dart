import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/security/app_lock.dart';
import '../../data/repositories/auth_repository.dart';

/// Signs out (unregistering push first), clears the lock and returns to login.
Future<void> signOut(BuildContext context) async {
  final authRepository = context.read<AuthRepository>();
  final appLock = context.read<AppLockController>();
  final router = GoRouter.of(context);
  await authRepository.logout();
  appLock.reset();
  router.go('/login');
}
