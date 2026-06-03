import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/constants/enums.dart';
import 'core/network/connectivity_manager.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/knowledge/presentation/bloc/faq_bloc.dart';
import 'features/knowledge/presentation/bloc/knowledge_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/tracking/presentation/bloc/tracking_bloc.dart';
import 'features/wallet/presentation/bloc/wallet_bloc.dart';

class SitukangApp extends StatelessWidget {
  const SitukangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested())),
        BlocProvider(create: (_) => getIt<NotificationBloc>()),
        BlocProvider(create: (_) => getIt<KnowledgeBloc>()),
        BlocProvider(create: (_) => getIt<FaqBloc>()),
        BlocProvider(create: (_) => getIt<TrackingBloc>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
      ],
      child: const _AppRouterWrapper(),
    );
  }
}

class _AppRouterWrapper extends StatefulWidget {
  const _AppRouterWrapper();

  @override
  State<_AppRouterWrapper> createState() => _AppRouterWrapperState();
}

class _AppRouterWrapperState extends State<_AppRouterWrapper> {
  late final router = createAppRouter(null, false);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          final role = state.user.role;
          final isWorker = role == UserRole.worker;
          router.go(isWorker ? '/worker' : '/home');
        } else if (state is Unauthenticated) {
          router.go('/login');
        }
      },
      child: MaterialApp.router(
        title: 'SiTukang',
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return ConnectivityBanner(
            connectivityManager: getIt<ConnectivityManager>(),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
