import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme.dart';

class UserAppShell extends StatelessWidget {
  const UserAppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/orders');
      case 2:
        context.go('/chat');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      selectedIndex: _selectedIndex(context),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        _ShellNavItem(Icons.home, 'Home'),
        _ShellNavItem(Icons.handyman, 'Orders'),
        _ShellNavItem(Icons.chat_bubble_outline, 'Chat'),
        _ShellNavItem(Icons.person_outline, 'Profile'),
      ],
      child: child,
    );
  }
}

class WorkerAppShell extends StatelessWidget {
  const WorkerAppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/worker/orders')) return 1;
    if (location.startsWith('/worker/chat')) return 2;
    if (location.startsWith('/worker/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/worker');
      case 1:
        context.go('/worker/orders');
      case 2:
        context.go('/worker/chat');
      case 3:
        context.go('/worker/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      selectedIndex: _selectedIndex(context),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        _ShellNavItem(Icons.home, 'Home'),
        _ShellNavItem(Icons.handyman, 'Orders'),
        _ShellNavItem(Icons.chat_bubble_outline, 'Chat'),
        _ShellNavItem(Icons.person_outline, 'Profile'),
      ],
      child: child,
    );
  }
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({
    required this.child,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final Widget child;
  final List<_ShellNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == selectedIndex;
              final color =
                  selected ? const Color(0xFF00758A) : const Color(0xFF424B50);
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(index),
                  child: SizedBox(
                    height: 68,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: color, size: 34),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
