class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String categoryName;
  final List<String> sizes;
  final String description;
  final double rating;
  final int reviewsCount;
  final bool isNew;
  final bool isTrending;
  final String vendor;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.categoryName,
    required this.sizes,
    required this.description,
    required this.rating,
    required this.reviewsCount,
    this.isNew = false,
    this.isTrending = false,
    required this.vendor,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      imageUrl: json['image_url'] ?? '',
      categoryName: json['category_name'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      description: json['description'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] ?? 0,
      isNew: json['is_new'] ?? false,
      isTrending: json['is_trending'] ?? false,
      vendor: json['vendor'] ?? '',
    );
  }
}
