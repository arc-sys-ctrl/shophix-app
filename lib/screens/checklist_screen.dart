import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/checklist_provider.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistProvider);
    final filteredItems = state.filteredItems;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        body: Stack(
          children: [
            // Background orbs
            _buildBgOrbs(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  _buildCategoryFilters(state),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? _buildEmptyState(state)
                        : _buildList(filteredItems),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: ScaleTransition(
          scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
          child: _buildFab(),
        ),
      ),
    );
  }

  // ─── Background ────────────────────────────────────────────────────────────

  Widget _buildBgOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: _orb(240, const Color(0xFF00D1FF), 0.07),
        ),
        Positioned(
          bottom: -100,
          left: -60,
          child: _orb(300, const Color(0xFF7C3AED), 0.07),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ChecklistState state) {
    final total = state.items.length;
    final checked = state.items.where((i) => i.isChecked).length;
    final allProgress = total == 0 ? 0.0 : checked / total;

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        final t = CurvedAnimation(parent: _headerController, curve: Curves.easeOut).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Lists',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'Nothing here yet'
                          : '$checked of $total completed',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                if (state.items.any((i) => i.isChecked))
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _confirmClearChecked();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Clear done',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 16),
              _buildOverallProgress(allProgress, checked, total),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress(double progress, int checked, int total) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00D1FF)),
                minHeight: 6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(progress * 100).round()}%',
          style: GoogleFonts.outfit(
            color: const Color(0xFF00D1FF),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── Category Filters ──────────────────────────────────────────────────────

  Widget _buildCategoryFilters(ChecklistState state) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _filterPill(
            label: 'All',
            emoji: '📋',
            isActive: state.activeFilter == null,
            onTap: () => ref.read(checklistProvider.notifier).setFilter(null),
            count: state.items.length,
          ),
          ...ChecklistCategory.values.map((cat) => _filterPill(
                label: cat.label,
                emoji: cat.emoji,
                isActive: state.activeFilter == cat,
                onTap: () =>
                    ref.read(checklistProvider.notifier).setFilter(cat),
                count: state.totalCount(cat),
              )),
        ],
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required String emoji,
    required bool isActive,
    required VoidCallback onTap,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00D1FF).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF00D1FF).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              count > 0 ? '$label ($count)' : label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF00D1FF) : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(List<ChecklistItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ChecklistTile(
          key: ValueKey(item.id),
          item: item,
          onToggle: () {
            HapticFeedback.lightImpact();
            ref.read(checklistProvider.notifier).toggleItem(item.id);
          },
          onDelete: () {
            HapticFeedback.mediumImpact();
            ref.read(checklistProvider.notifier).deleteItem(item.id);
          },
        );
      },
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(ChecklistState state) {
    final cat = state.activeFilter;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cat != null ? cat.emoji : '✨',
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 16),
          Text(
            cat != null ? 'No ${cat.label} items' : 'Your lists are empty',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first item',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showAddItemSheet(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D1FF), Color(0xFF0057FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D1FF).withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // ─── Add Item Sheet ────────────────────────────────────────────────────────

  void _showAddItemSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    ChecklistCategory selectedCat =
        ref.read(checklistProvider).activeFilter ?? ChecklistCategory.shopping;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.97),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Item',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Category picker
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ChecklistCategory.values.map((cat) {
                          final active = selectedCat == cat;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedCat = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF00D1FF)
                                        .withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: active
                                      ? const Color(0xFF00D1FF)
                                          .withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              child: Text(
                                '${cat.emoji} ${cat.label}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: active
                                      ? const Color(0xFF00D1FF)
                                      : Colors.white54,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title field
                    _sheetField(
                      controller: titleCtrl,
                      hint: 'Item title (e.g., Nike Air Max)',
                      icon: Icons.edit_outlined,
                    ),
                    const SizedBox(height: 12),
                    // Note field (optional)
                    _sheetField(
                      controller: noteCtrl,
                      hint: 'Note (optional)',
                      icon: Icons.notes_outlined,
                    ),
                    const SizedBox(height: 24),
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) return;
                          ref.read(checklistProvider.notifier).addItem(
                                title: titleCtrl.text,
                                category: selectedCat,
                                note: noteCtrl.text.trim().isEmpty
                                    ? null
                                    : noteCtrl.text,
                              );
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D1FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ADD ITEM',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00D1FF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // ─── Confirm clear ─────────────────────────────────────────────────────────

  void _confirmClearChecked() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Completed?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will remove all checked items permanently.',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              ref.read(checklistProvider.notifier).clearChecked();
              Navigator.pop(ctx);
            },
            child: Text('Clear',
                style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Checklist Tile ────────────────────────────────────────────────────────

class _ChecklistTile extends StatefulWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ChecklistTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_ChecklistTile> createState() => _ChecklistTileState();
}

class _ChecklistTileState extends State<_ChecklistTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.item.isChecked ? 1.0 : 0.0,
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _checkController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_ChecklistTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isChecked != oldWidget.item.isChecked) {
      if (widget.item.isChecked) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final catColor = _catColor(item.category);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFEF4444), size: 24),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: item.isChecked
                ? Colors.white.withValues(alpha: 0.02)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isChecked
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              // Animated check circle
              ScaleTransition(
                scale: _checkScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color:
                        item.isChecked ? const Color(0xFF00D1FF) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isChecked
                          ? const Color(0xFF00D1FF)
                          : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.black)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: item.isChecked
                          ? GoogleFonts.inter(
                              color: Colors.white24,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white24,
                            )
                          : GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                      child: Text(item.title),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.note!,
                        style: GoogleFonts.inter(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: catColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  item.category.emoji,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _catColor(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.shopping:
        return const Color(0xFF00D1FF);
      case ChecklistCategory.packing:
        return const Color(0xFF10B981);
      case ChecklistCategory.outfit:
        return const Color(0xFFEC4899);
      case ChecklistCategory.wishlist:
        return const Color(0xFF7C3AED);
    }
  }
}
