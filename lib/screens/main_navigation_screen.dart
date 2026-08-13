import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/data/models/report.dart';
import 'package:sikayet_uygulamasi/data/models/user.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/screens/admin_dashboard_screen.dart';
import '../core/app_colors.dart';
import 'home_screen.dart';
import 'report_list_screen.dart';
import 'profile_screen.dart';
import '../providers/auth_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canManageUsers =
        user?.role == UserRole.admin || user?.role == UserRole.managing;

    final reportAsync = ref.watch(reportListProvider);
    final hasPending =
        reportAsync.valueOrNull?.any((r) => r.status == ReportStatus.pending) ??
        false;

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.role != next?.role) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
        }
      }
    });

    final List<Widget> screens = [
      const HomeScreen(),
      const ReportListScreen(),
      if (canManageUsers) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    final List<_NavItem> items = [
      _NavItem(
        icon: Icons.map_outlined,
        selectedIcon: Icons.map,
        label: 'Harita',
      ),
      _NavItem(
        icon: Icons.list_alt,
        selectedIcon: Icons.view_list,
        label: 'Kayıtlar',
      ),
      if (canManageUsers)
        _NavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Yönetim',
          hasBadge: hasPending,
        ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profil',
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: FadeIndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final isSelected = safeIndex == i;
                final item = items[i];

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDarkMode
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : const Color(0xFFEEF1F4))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topRight,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? (isDarkMode
                                        ? theme.colorScheme.primary
                                        : AppColors.navy)
                                  : (isDarkMode
                                        ? Colors.grey.shade500
                                        : const Color(0xFFB4B2A9)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? (isDarkMode
                                          ? theme.colorScheme.primary
                                          : AppColors.navy)
                                    : (isDarkMode
                                          ? Colors.grey.shade500
                                          : const Color(0xFFB4B2A9)),
                              ),
                            ),
                          ],
                        ),
                        if (item.hasBadge)
                          Positioned(
                            top: -2,
                            right: -6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
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

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool hasBadge;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.hasBadge = false,
  });
}

// ekranlar arası geçişi yumuşatır
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });
  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}
