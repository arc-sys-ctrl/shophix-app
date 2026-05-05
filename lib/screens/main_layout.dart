import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'checklist_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(productsProvider);
      ref.invalidate(homeRailsProvider);
      ref.invalidate(trendingProductsProvider);
      ref.invalidate(newArrivalsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(productsInCategoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    const pages = [
      HomeScreen(),
      SearchScreen(),
      CartScreen(),
      ChecklistScreen(),
      ProfileScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: SophixColors.navBar,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: SophixColors.background,
        body: IndexedStack(
          index: currentTab,
          children: pages,
        ),
        bottomNavigationBar: _SophixNavBar(
          currentIndex: currentTab,
          onTap: (index) => ref.read(currentTabProvider.notifier).setTab(index),
        ),
      ),
    );
  }
}

class _SophixNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SophixNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: SophixColors.navBar.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Discover', index: 1, currentIndex: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'Cart', index: 2, currentIndex: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.checklist_outlined, activeIcon: Icons.checklist_rounded, label: 'Lists', index: 3, currentIndex: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 4, currentIndex: currentIndex, onTap: onTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return SizedBox(
      width: 68,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(index);
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: SophixColors.accent.withValues(alpha: 0.15),
          highlightColor: SophixColors.accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? SophixColors.accent.withValues(alpha: 0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? SophixColors.accent : Colors.white38,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? SophixColors.accent : Colors.white38,
                    letterSpacing: isActive ? 0.2 : 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
