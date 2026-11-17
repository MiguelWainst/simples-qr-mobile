import 'dart:convert';

typedef Json = Map<String, dynamic>;

class Restaurant {
  const Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description = '',
    this.published = false,
    this.imageUrl,
    this.logoUrl,
    this.menuAccent,
    this.menuTitle,
  });
  final String id, ownerId, name, slug, description;
  final bool published;
  final String? imageUrl;
  final String? logoUrl, menuAccent, menuTitle;
  String get displayTitle => menuTitle ?? name;
  factory Restaurant.fromMap(Json m) => Restaurant(
    id: m['id'] as String,
    ownerId: m['owner_id'] as String,
    name: m['name'] as String,
    slug: m['slug'] as String,
    description: m['description'] as String? ?? '',
    published: m['published'] as bool? ?? false,
    imageUrl: m['image_url'] as String?,
    logoUrl: m['logo_url'] as String?,
    menuAccent: m['menu_accent'] as String?,
    menuTitle: m['menu_title'] as String?,
  );
  Json toMap() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'slug': slug,
    'description': description,
    'published': published,
    'image_url': imageUrl,
    'logo_url': logoUrl,
    'menu_accent': menuAccent,
    'menu_title': menuTitle,
  };
  String toJson() => jsonEncode(toMap());
  factory Restaurant.fromJson(String value) =>
      Restaurant.fromMap(jsonDecode(value) as Json);
}

class Category {
  const Category({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.position = 0,
  });
  final String id, restaurantId, name;
  final int position;
  factory Category.fromMap(Json m) => Category(
    id: m['id'] as String,
    restaurantId: m['restaurant_id'] as String,
    name: m['name'] as String,
    position: m['position'] as int? ?? 0,
  );
  Json toMap() => {
    'id': id,
    'restaurant_id': restaurantId,
    'name': name,
    'position': position,
  };
  String toJson() => jsonEncode(toMap());
  factory Category.fromJson(String value) =>
      Category.fromMap(jsonDecode(value) as Json);
}

class Product {
  const Product({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.priceCents,
    this.description = '',
    this.available = true,
    this.imageUrl,
    this.salePriceCents,
    this.flashEndsAt,
    this.isNew = false,
  });
  final String id, restaurantId, categoryId, name, description;
  final int priceCents;
  final bool available;
  final String? imageUrl;
  final int? salePriceCents;
  final DateTime? flashEndsAt;
  final bool isNew;

  String get price => formatPrice(priceCents);
  int? activeSaleAt(DateTime now) {
    final sale = salePriceCents;
    if (sale == null || sale < 0 || sale >= priceCents) return null;
    final end = flashEndsAt;
    return end == null || end.isAfter(now) ? sale : null;
  }

  static String formatPrice(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  factory Product.fromMap(Json m) => Product(
    id: m['id'] as String,
    restaurantId: m['restaurant_id'] as String,
    categoryId: m['category_id'] as String,
    name: m['name'] as String,
    priceCents: m['price_cents'] as int,
    description: m['description'] as String? ?? '',
    available: m['available'] as bool? ?? true,
    imageUrl: m['image_url'] as String?,
    salePriceCents: m['sale_price_cents'] as int?,
    flashEndsAt: DateTime.tryParse(m['flash_ends_at'] as String? ?? ''),
    isNew: m['is_new'] as bool? ?? false,
  );
  Json toMap() => {
    'id': id,
    'restaurant_id': restaurantId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price_cents': priceCents,
    'available': available,
    'image_url': imageUrl,
    'sale_price_cents': salePriceCents,
    'flash_ends_at': flashEndsAt?.toUtc().toIso8601String(),
    'is_new': isNew,
  };
  String toJson() => jsonEncode(toMap());
  factory Product.fromJson(String value) =>
      Product.fromMap(jsonDecode(value) as Json);
}

abstract final class Rules {
  static String? menuAccent(String value) {
    final normalized = value.trim().toUpperCase();
    return RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized) ? normalized : null;
  }

  static String? name(String? value, {int min = 1, int max = 120}) =>
      (value ?? '').trim().length < min || (value ?? '').trim().length > max
      ? 'Use de $min a $max caracteres.'
      : null;
  static String? email(String? value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
      ? null
      : 'Informe um e-mail válido.';
  static String? password(String? value) =>
      (value ?? '').length >= 8 ? null : 'Use pelo menos 8 caracteres.';
  static String? slug(String? value) =>
      RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(value ?? '') &&
          (value ?? '').length <= 80
      ? null
      : 'Use letras minúsculas, números e hífens.';
  static int? cents(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(normalized)) {
      return null;
    }
    final parts = normalized.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }

  static String? menuCode(String input) {
    final value = input.trim();
    if (slug(value) == null) {
      return value;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !['https', 'http', 'simplesqr'].contains(uri.scheme)) {
      return null;
    }
    final fragment = Uri.tryParse(uri.fragment);
    final candidate =
        uri.queryParameters['menu'] ?? fragment?.queryParameters['menu'];
    return candidate != null && slug(candidate) == null ? candidate : null;
  }
}
