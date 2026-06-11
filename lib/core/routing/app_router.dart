import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/chat/domain/entities/chat_conversation.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/worker_chat_page.dart';
import '../../features/home/domain/entities/active_order.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/invoice/domain/entities/invoice.dart';
import '../../features/knowledge/presentation/pages/help_center_page.dart';
import '../../features/notifications/presentation/pages/notification_list_page.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';
import '../../features/orders/presentation/pages/order_create_page.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/worker_history/presentation/bloc/worker_history_bloc.dart';
import '../../features/worker_history/presentation/pages/worker_history_page.dart';
import '../../features/worker_home/presentation/bloc/worker_home_bloc.dart';
import '../../features/worker_home/presentation/pages/worker_home_page.dart';
import '../../features/worker_orders/domain/entities/worker_order_detail.dart';
import '../../features/worker_orders/presentation/bloc/incoming_order_bloc.dart';
import '../../features/worker_orders/presentation/bloc/worker_order_bloc.dart';
import '../../features/worker_orders/presentation/pages/incoming_order_page.dart';
import '../../features/worker_orders/presentation/pages/worker_active_order_page.dart';
import '../../features/worker_orders/presentation/pages/worker_invoice_page.dart';
import '../../features/worker_orders/presentation/pages/worker_order_detail_brief_page.dart';
import '../../features/worker_orders/presentation/pages/worker_order_items_page.dart';
import '../../features/worker_profile/presentation/bloc/worker_profile_bloc.dart';
import '../../features/worker_profile/presentation/pages/worker_profile_page.dart';
import '../../features/workers/domain/entities/worker_profile.dart';
import '../../features/workers/presentation/bloc/worker_detail_bloc.dart';
import '../../features/workers/presentation/bloc/worker_list_bloc.dart';
import '../../features/workers/presentation/pages/nearby_workers_page.dart';
import '../../features/workers/presentation/pages/worker_detail_page.dart';
import '../../routing/route_guards.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _userShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'userShell');
final GlobalKey<NavigatorState> _workerShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'workerShell');

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
        builder: (context, state) =>
            RegisterPage(onLoginTap: () => context.pop()),
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
          return MultiBlocProvider(
            providers: [
              BlocProvider<HomeBloc>(create: (_) => getIt<HomeBloc>()),
              BlocProvider<OrderBloc>(create: (_) => getIt<OrderBloc>()),
              BlocProvider<ChatBloc>(create: (_) => getIt<ChatBloc>()),
              BlocProvider<ProfileBloc>(create: (_) => getIt<ProfileBloc>()),
            ],
            child: UserAppShell(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) {
              final order = state.extra is Order ? state.extra as Order : null;
              return HomePage(
                initialActiveOrder: order == null
                    ? null
                    : ActiveOrder(
                        orderId: order.id,
                        status: order.status,
                        workerName: order.workerInfo?.fullName ?? 'Tukang',
                        serviceName: order.serviceName ?? order.title,
                      ),
              );
            },
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrderListPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) {
              final authState = context.read<AuthBloc>().state;
              final currentUserId = authState is Authenticated
                  ? authState.user.id
                  : '';
              return ChatListPage(currentUserId: currentUserId);
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final orderId = state.pathParameters['id']!;
                  final conversation = state.extra is ChatConversation
                      ? state.extra as ChatConversation
                      : null;
                  final workerName =
                      conversation?.workerName ??
                      (state.extra is String
                          ? state.extra as String
                          : 'Tukang');
                  final authState = context.read<AuthBloc>().state;
                  final currentUserId = authState is Authenticated
                      ? authState.user.id
                      : '';
                  return ChatPage(
                    orderId: orderId,
                    workerName: workerName,
                    workerAvatarUrl: conversation?.workerAvatarUrl,
                    isWorkerOnline: conversation?.isOnline ?? false,
                    currentUserId: currentUserId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
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
          // Partial worker data may be passed via extra to show immediately
          // while the detail API call is in progress (or if it fails with 500)
          final preloadedWorker = state.extra is WorkerProfile
              ? state.extra as WorkerProfile
              : null;

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<WorkerDetailBloc>()
                  ..add(
                    FetchWorkerDetail(
                      workerId: workerId,
                      preloadedWorker: preloadedWorker,
                    ),
                  ),
              ),
              BlocProvider(create: (_) => getIt<OrderBloc>()),
            ],
            child: WorkerDetailPage(workerId: workerId),
          );
        },
      ),
      GoRoute(
        path: '/workers/:id/order',
        builder: (context, state) {
          final workerId = state.pathParameters['id']!;
          final extraMap = state.extra as Map<String, dynamic>? ?? {};

          return BlocProvider(
            create: (_) => getIt<OrderBloc>(),
            child: OrderCreatePage(
              workerId: workerId,
              workerProfile: extraMap['workerProfile'] as WorkerProfile?,
              selectedServiceId: extraMap['selectedServiceId'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/worker/orders/:id/brief',
        parentNavigatorKey: rootNavigatorKey,
        redirect: RoleGuard.workerRedirect,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => getIt<WorkerOrderBloc>(),
            child: WorkerOrderDetailBriefPage(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/worker/orders/:id/items',
        parentNavigatorKey: rootNavigatorKey,
        redirect: RoleGuard.workerRedirect,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          final detail = state.extra is WorkerOrderDetail
              ? state.extra as WorkerOrderDetail
              : null;
          return WorkerOrderItemsPage(orderId: orderId, detail: detail);
        },
      ),
      GoRoute(
        path: '/worker/orders/:id/invoice',
        parentNavigatorKey: rootNavigatorKey,
        redirect: RoleGuard.workerRedirect,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          final invoice = state.extra is Invoice
              ? state.extra as Invoice
              : null;
          return WorkerInvoicePage(orderId: orderId, invoice: invoice);
        },
      ),

      // WORKER ROUTES (Shell)
      ShellRoute(
        navigatorKey: _workerShellNavigatorKey,
        redirect: RoleGuard.workerRedirect,
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<WorkerHomeBloc>(
                create: (_) => getIt<WorkerHomeBloc>(),
              ),
              BlocProvider<IncomingOrderBloc>(
                create: (_) => getIt<IncomingOrderBloc>(),
              ),
              BlocProvider<ChatBloc>(create: (_) => getIt<ChatBloc>()),
              BlocProvider<WorkerProfileBloc>(
                create: (_) => getIt<WorkerProfileBloc>(),
              ),
            ],
            child: WorkerAppShell(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/worker',
            builder: (context, state) => const WorkerHomePage(),
          ),
          GoRoute(
            path: '/worker/orders',
            builder: (context, state) {
              final order = state.extra;
              if (order is! Order) {
                return BlocProvider(
                  create: (_) => getIt<WorkerHistoryBloc>(),
                  child: const WorkerHistoryPage(),
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
            builder: (context, state) {
              final authState = context.read<AuthBloc>().state;
              final currentUserId = authState is Authenticated
                  ? authState.user.id
                  : '';
              return ChatListPage(isWorker: true, currentUserId: currentUserId);
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final orderId = state.pathParameters['id']!;
                  final conversation = state.extra is ChatConversation
                      ? state.extra as ChatConversation
                      : null;
                  final customerName =
                      conversation?.workerName ??
                      (state.extra is String
                          ? state.extra as String
                          : 'Pelanggan');
                  final authState = context.read<AuthBloc>().state;
                  final currentUserId = authState is Authenticated
                      ? authState.user.id
                      : '';
                  return WorkerChatPage(
                    orderId: orderId,
                    customerName: customerName,
                    customerAvatarUrl: conversation?.workerAvatarUrl,
                    isCustomerOnline: conversation?.isOnline ?? false,
                    currentUserId: currentUserId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/worker/profile',
            builder: (context, state) => const WorkerProfilePage(),
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
        path: '/worker/wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/worker/incoming-order/:id',
        builder: (context, state) => const IncomingOrderPage(),
      ),
    ],
  );
}
