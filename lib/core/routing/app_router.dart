import '../../core/constants/enums.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../features/orders/presentation/pages/order_create_page.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/workers/domain/entities/worker_service.dart';
import '../../features/workers/presentation/bloc/worker_detail_bloc.dart';
import '../../features/workers/presentation/bloc/worker_list_bloc.dart';
import '../../features/workers/presentation/pages/nearby_workers_page.dart';
import '../../features/workers/presentation/pages/worker_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/worker_home/presentation/bloc/worker_home_bloc.dart';
import '../../features/worker_orders/presentation/bloc/worker_order_bloc.dart';
import '../../features/worker_orders/presentation/bloc/incoming_order_bloc.dart';
import '../../features/worker_profile/presentation/bloc/worker_profile_bloc.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/worker_home/presentation/pages/worker_home_page.dart';
import '../../features/worker_orders/presentation/pages/worker_active_order_page.dart';
import '../../features/worker_orders/presentation/pages/incoming_order_page.dart';
import '../../features/worker_profile/presentation/pages/worker_profile_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/worker_chat_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/notifications/presentation/pages/notification_list_page.dart';
import '../../features/knowledge/presentation/pages/help_center_page.dart';
import '../../features/worker_history/presentation/pages/worker_history_page.dart';
import '../../routing/route_guards.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _userShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'userShell');
final GlobalKey<NavigatorState> _workerShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'workerShell');

GoRouter createAppRouter(String? initialRole, bool isAuthenticated) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: isAuthenticated 
        ? (initialRole == 'worker' ? '/worker' : '/home') 
        : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          onRegisterTap: () => context.push('/register'),
          onForgotPasswordTap: () => context.push('/forgot-password'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterPage(
          onLoginTap: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      
      // USER ROUTES (Shell)
      ShellRoute(
        navigatorKey: _userShellNavigatorKey,
        redirect: RoleGuard.userRedirect,
        builder: (context, state, child) {
          return UserAppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<HomeBloc>(),
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<OrderBloc>(),
              child: const OrderListPage(),
            ),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ChatBloc>(),
              child: const ChatListPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final orderId = state.pathParameters['id']!;
                  // we could pass workerName through extra
                  final workerName = state.extra as String? ?? 'Tukang';
                  return ChatPage(orderId: orderId, workerName: workerName, currentUserId: '1');
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ProfileBloc>(),
              child: const ProfilePage(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/workers',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<WorkerListBloc>(),
          child: const NearbyWorkersPage(),
        ),
      ),
      GoRoute(
        path: '/workers/:id',
        builder: (context, state) {
          final workerId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => getIt<WorkerDetailBloc>()
              ..add(FetchWorkerDetail(workerId: workerId)),
            child: WorkerDetailPage(
              workerId: workerId,
              onBookNow: (worker) => context.push(
                '/workers/$workerId/order',
                extra: {
                  'workerName': worker.fullName,
                  'workerAvatarUrl': worker.avatarUrl,
                  'services': worker.services,
                },
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/workers/:id/order',
        builder: (context, state) {
          final workerId = state.pathParameters['id']!;
          final worker = state.extra;
          String workerName = 'Tukang';
          String? workerAvatarUrl;
          var services = const <OrderServiceOption>[];

          if (worker is Map<String, dynamic>) {
            workerName = worker['workerName'] as String? ?? workerName;
            workerAvatarUrl = worker['workerAvatarUrl'] as String?;
            final rawServices = worker['services'];
            if (rawServices is List<WorkerService>) {
              services = rawServices
                  .map(
                    (service) => OrderServiceOption(
                      id: service.id,
                      name: service.name,
                      basePrice: service.basePrice,
                    ),
                  )
                  .toList();
            }
          }

          return BlocProvider(
            create: (_) => getIt<OrderBloc>(),
            child: OrderCreatePage(
              workerId: workerId,
              workerName: workerName,
              workerAvatarUrl: workerAvatarUrl,
              services: services,
            ),
          );
        },
      ),

      // WORKER ROUTES (Shell)
      ShellRoute(
        navigatorKey: _workerShellNavigatorKey,
        redirect: RoleGuard.workerRedirect,
        builder: (context, state, child) {
          return WorkerAppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/worker',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<WorkerHomeBloc>(),
              child: const WorkerHomePage(),
            ),
          ),
          GoRoute(
            path: '/worker/orders',
            builder: (context, state) {
              final order = state.extra;
              if (order is! Order) {
                return BlocProvider(
                  create: (_) => getIt<IncomingOrderBloc>(),
                  child: const IncomingOrderPage(),
                );
              }

              return BlocProvider(
                create: (_) => getIt<WorkerOrderBloc>(),
                child: WorkerActiveOrderPage(order: order),
              );
            },
          ),
          GoRoute(
            path: '/worker/chat',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ChatBloc>(),
              child: const ChatListPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final orderId = state.pathParameters['id']!;
                  final customerName = state.extra as String? ?? 'Pelanggan';
                  return WorkerChatPage(orderId: orderId, customerName: customerName, currentUserId: '1');
                },
              ),
            ],
          ),
          GoRoute(
            path: '/worker/profile',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<WorkerProfileBloc>(),
              child: const WorkerProfilePage(),
            ),
          ),
        ],
      ),
      
      // Global/Shared Routes (Outside shell)
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListPage(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/worker/history',
        builder: (context, state) => const WorkerHistoryPage(),
      ),
      GoRoute(
        path: '/worker/wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/worker/incoming-order/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return const IncomingOrderPage();
        },
      ),
    ],
  );
}
