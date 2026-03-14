import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

// ── Sidebar ───────────────────────────────────────────────────────────────────
class AppSidebar extends ConsumerWidget {
  final String currentRoute;
  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F111A), // Deeper navy for sidebar
        border: Border(right: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.casino_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Awra',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          _navItem(context, ref, Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
          _navItem(context, ref, Icons.casino_rounded, 'Game', '/game'),
          const Spacer(),
          const Divider(color: AppTheme.border, height: 1),
          _navItem(context, ref, Icons.logout_rounded, 'Logout', '/logout', isDestructive: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String label,
    String route, {
    bool isDestructive = false,
  }) {
    final active = currentRoute == route;
    final color = isDestructive
        ? AppTheme.accentRed
        : active
            ? AppTheme.accent
            : AppTheme.textSub;

    return GestureDetector(
      onTap: () async {
        if (route == '/logout') {
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
        } else if (!active) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppTheme.accent.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'Outfit',
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class AppTopBar extends ConsumerWidget {
  final String title;
  const AppTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: AppTheme.accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  user?.displayName ?? user?.email ?? 'Operator',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
