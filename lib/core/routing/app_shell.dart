import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserAppShell extends StatelessWidget {
  const UserAppShell({required this.child, super.key});

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
        _ShellNavItem(
          activeIcon: Icons.home,
          inactiveIcon: Icons.home_outlined,
          label: 'Home',
        ),
        _ShellNavItem(
          activeIcon: Icons.handyman,
          inactiveIcon: Icons.handyman_outlined,
          label: 'Orders',
        ),
        _ShellNavItem(
          activeIcon: Icons.chat_bubble,
          inactiveIcon: Icons.chat_bubble_outline,
          label: 'Chat',
        ),
        _ShellNavItem(
          activeIcon: Icons.person,
          inactiveIcon: Icons.person_outline,
          label: 'Profile',
        ),
      ],
      child: child,
    );
  }
}

class WorkerAppShell extends StatelessWidget {
  const WorkerAppShell({required this.child, super.key});

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
        _ShellNavItem(
          activeIcon: Icons.home,
          inactiveIcon: Icons.home_outlined,
          label: 'Home',
        ),
        _ShellNavItem(
          activeIcon: Icons.handyman,
          inactiveIcon: Icons.handyman_outlined,
          label: 'Orders',
        ),
        _ShellNavItem(
          activeIcon: Icons.chat_bubble,
          inactiveIcon: Icons.chat_bubble_outline,
          label: 'Chat',
        ),
        _ShellNavItem(
          activeIcon: Icons.person,
          inactiveIcon: Icons.person_outline,
          label: 'Profile',
        ),
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == selectedIndex;
                final color = selected ? const Color(0xFF00758A) : const Color(0xFF8E8E93);
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.inactiveIcon,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}
