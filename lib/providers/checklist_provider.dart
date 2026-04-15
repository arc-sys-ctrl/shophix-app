import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ─── Categories ────────────────────────────────────────────────────────────

enum ChecklistCategory {
  shopping,
  packing,
  outfit,
  wishlist,
}

extension ChecklistCategoryExt on ChecklistCategory {
  String get label {
    switch (this) {
      case ChecklistCategory.shopping:
        return 'Shopping List';
      case ChecklistCategory.packing:
        return 'Packing List';
      case ChecklistCategory.outfit:
        return 'Outfit Ideas';
      case ChecklistCategory.wishlist:
        return 'Wishlist';
    }
  }

  String get emoji {
    switch (this) {
      case ChecklistCategory.shopping:
        return '🛍️';
      case ChecklistCategory.packing:
        return '🧳';
      case ChecklistCategory.outfit:
        return '👗';
      case ChecklistCategory.wishlist:
        return '✨';
    }
  }

  String get key => name;
}

// ─── Model ─────────────────────────────────────────────────────────────────

class ChecklistItem {
  final String id;
  final String title;
  final ChecklistCategory category;
  final bool isChecked;
  final DateTime createdAt;
  final String? note;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    this.isChecked = false,
    required this.createdAt,
    this.note,
  });

  ChecklistItem copyWith({
    String? title,
    ChecklistCategory? category,
    bool? isChecked,
    String? note,
  }) {
    return ChecklistItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.key,
        'isChecked': isChecked,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ChecklistCategory.values.firstWhere(
        (c) => c.key == json['category'],
        orElse: () => ChecklistCategory.shopping,
      ),
      isChecked: json['isChecked'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}

// ─── State ─────────────────────────────────────────────────────────────────

class ChecklistState {
  final List<ChecklistItem> items;
  final ChecklistCategory? activeFilter; // null = All

  const ChecklistState({
    this.items = const [],
    this.activeFilter,
  });

  ChecklistState copyWith({
    List<ChecklistItem>? items,
    ChecklistCategory? Function()? activeFilter,
  }) {
    return ChecklistState(
      items: items ?? this.items,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
    );
  }

  List<ChecklistItem> get filteredItems {
    if (activeFilter == null) return items;
    return items.where((i) => i.category == activeFilter).toList();
  }

  int checkedCount(ChecklistCategory cat) =>
      items.where((i) => i.category == cat && i.isChecked).length;

  int totalCount(ChecklistCategory cat) =>
      items.where((i) => i.category == cat).length;

  double progress(ChecklistCategory cat) {
    final total = totalCount(cat);
    if (total == 0) return 0.0;
    return checkedCount(cat) / total;
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

const _prefsKey = 'sophix_checklist_items';
const _uuid = Uuid();

class ChecklistNotifier extends Notifier<ChecklistState> {
  @override
  ChecklistState build() {
    Future.microtask(_load);
    return const ChecklistState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
        .toList();
    state = state.copyWith(items: list);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.items.map((e) => e.toJson()).toList()),
    );
  }

  void addItem({
    required String title,
    required ChecklistCategory category,
    String? note,
  }) {
    final item = ChecklistItem(
      id: _uuid.v4(),
      title: title.trim(),
      category: category,
      createdAt: DateTime.now(),
      note: note?.trim(),
    );
    state = state.copyWith(items: [item, ...state.items]);
    _persist();
  }

  void toggleItem(String id) {
    state = state.copyWith(
      items: state.items
          .map((i) => i.id == id ? i.copyWith(isChecked: !i.isChecked) : i)
          .toList(),
    );
    _persist();
  }

  void deleteItem(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
    _persist();
  }

  void clearChecked() {
    state = state.copyWith(
      items: state.items.where((i) => !i.isChecked).toList(),
    );
    _persist();
  }

  void setFilter(ChecklistCategory? cat) {
    state = state.copyWith(activeFilter: () => cat);
  }
}

final checklistProvider =
    NotifierProvider<ChecklistNotifier, ChecklistState>(ChecklistNotifier.new);
