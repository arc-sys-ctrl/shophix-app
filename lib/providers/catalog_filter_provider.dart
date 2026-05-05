import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When set, Browse (search) tab shows products in this category (from loaded catalog).
class BrowseCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final browseCategoryFilterProvider =
    NotifierProvider<BrowseCategoryFilterNotifier, String?>(() {
  return BrowseCategoryFilterNotifier();
});
