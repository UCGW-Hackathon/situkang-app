import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';


class AuthGuard {
  static FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (authState is Unauthenticated || authState is AuthInitial) {
      if (!isLoggingIn) return '/login';
    } else if (authState is Authenticated) {
      if (isLoggingIn) {
        final isWorker = authState.user.role == UserRole.worker;
        return isWorker ? '/worker' : '/home';
      }
    }
    return null;
  }
}

class RoleGuard {
  static FutureOr<String?> workerRedirect(BuildContext context, GoRouterState state) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      if (authState.user.role != UserRole.worker) {
        return '/home';
      }
    }
    return null;
  }

  static FutureOr<String?> userRedirect(BuildContext context, GoRouterState state) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      if (authState.user.role == UserRole.worker) {
        return '/worker';
      }
    }
    return null;
  }
}
