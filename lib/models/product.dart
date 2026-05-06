import '../config/env_config.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> imageUrls;
  final String categoryName;
  final List<String> sizes;
  final String description;
  final double rating;
  final int reviewsCount;
  final bool isNew;
  final bool isTrending;
  final String vendor;
  /// `active`, `draft`, `out_of_stock` from CRM — drafts are hidden on the client if present.
  final String? status;
  /// ISO or DB timestamp; used to bust image cache when CRM updates media.
  final String? updatedAt;

  bool get isStorefrontVisible =>
      status == null || status == 'active' || status == 'out_of_stock';

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.imageUrls,
    required this.categoryName,
    required this.sizes,
    required this.description,
    required this.rating,
    required this.reviewsCount,
    this.isNew = false,
    this.isTrending = false,
    required this.vendor,
    this.status,
    this.updatedAt,
  });

  /// Turns `/api/uploads/...` into a full URL for [CachedNetworkImage].
  static String _resolveMediaUrl(String? path, {String? cacheBust}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = EnvConfig.baseUrl;
    final uri = Uri.parse(base);
    final origin = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
    String url;
    if (path.startsWith('/')) {
      url = '$origin$path';
    } else {
      url = '$origin/$path';
    }
    if (cacheBust != null && cacheBust.isNotEmpty) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}v=${Uri.encodeComponent(cacheBust)}';
    }
    return url;
  }

  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawMain =
        (json['image_url'] as String?) ??
        (json['imageUrl'] as String?) ??
        (json['thumbnail'] as String?) ??
        '';
    final dynamic rawImagesAny = json['image_urls'] ?? json['imageUrls'] ?? const [];
    final List<String> rawList = rawImagesAny is List
        ? rawImagesAny.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
        : const [];
    final String mainCandidate = rawMain.isNotEmpty
        ? rawMain
        : (rawList.isNotEmpty ? rawList.first : '');
    final bust = json['updated_at']?.toString() ?? json['updatedAt']?.toString();
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      price: _toDouble(json['price']),
      originalPrice: json['original_price'] == null ? null : _toDouble(json['original_price']),
      imageUrl: _resolveMediaUrl(mainCandidate, cacheBust: bust),
      imageUrls: rawList.map((p) => _resolveMediaUrl(p, cacheBust: bust)).toList(),
      categoryName: json['category_name'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      description: json['description'] ?? '',
      rating: _toDouble(json['rating']),
      reviewsCount: _toInt(json['reviews_count']),
      isNew: json['is_new'] ?? false,
      isTrending: json['is_trending'] ?? false,
      vendor: json['vendor'] ?? '',
      status: json['status']?.toString(),
      updatedAt: bust,
    );
  }
}
