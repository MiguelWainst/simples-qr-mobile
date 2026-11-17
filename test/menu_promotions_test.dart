import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simples_qr/domain/catalog.dart';
import 'package:simples_qr/shared/widgets/catalog_widgets.dart';
import 'package:simples_qr/shared/widgets/product_offer.dart';

const _product = Product(
  id: 'p',
  restaurantId: 'r',
  categoryId: 'c',
  name: 'Hambúrguer da casa',
  priceCents: 2500,
);

void main() {
  test('cache preserva ofertas e interpreta registros antigos', () {
    final end = DateTime.utc(2026, 11, 17, 20);
    final product = Product.fromMap({
      ..._product.toMap(),
      'sale_price_cents': 1900,
      'flash_ends_at': end.toIso8601String(),
      'is_new': true,
    });
    final cached = Product.fromJson(product.toJson());
    expect(cached.isNew, isTrue);
    expect(cached.activeSaleAt(end.subtract(const Duration(seconds: 1))), 1900);
    expect(cached.activeSaleAt(end), isNull);

    final old = Product.fromMap(
      _product.toMap()
        ..remove('sale_price_cents')
        ..remove('flash_ends_at')
        ..remove('is_new'),
    );
    expect(old.activeSaleAt(end), isNull);
    expect(old.isNew, isFalse);

    final regular = Product.fromMap({
      ..._product.toMap(),
      'sale_price_cents': 1900,
    });
    expect(regular.activeSaleAt(end), 1900);
  });

  test('logo, título e cor do cardápio sobrevivem ao cache', () {
    const restaurant = Restaurant(
      id: 'r',
      ownerId: 'u',
      name: 'Café',
      slug: 'cafe',
      imageUrl: 'https://example.com/cover.jpg',
      logoUrl: 'https://example.com/logo.png',
      menuTitle: 'Cardápio do Café',
      menuAccent: '#852545',
    );
    final cached = Restaurant.fromJson(restaurant.toJson());
    expect(cached.toMap(), restaurant.toMap());
    expect(cached.displayTitle, 'Cardápio do Café');
    expect(Rules.menuAccent(' #85254a '), '#85254A');
    expect(Rules.menuAccent('#fff'), isNull);
  });

  testWidgets('oferta relâmpago termina na tela com a volta do preço normal', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 11, 17, 20);
    final product = Product.fromMap({
      ..._product.toMap(),
      'sale_price_cents': 1900,
      'flash_ends_at': now.add(const Duration(seconds: 2)).toIso8601String(),
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: PriceLabel(product, now: () => now),
          ),
        ),
      ),
    );
    expect(find.text('00:02'), findsOneWidget);
    final oldPrice = tester.widget<Text>(find.text('R\$ 25,00'));
    expect(oldPrice.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('R\$ 19,00'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Relâmpago'), findsNothing);
    expect(find.text('R\$ 19,00'), findsNothing);
    final normalPrice = tester.widget<Text>(find.text('R\$ 25,00'));
    expect(normalPrice.style?.decoration, isNull);
  });

  testWidgets('selo NEW e promoção regular são independentes', (tester) async {
    final product = Product.fromMap({
      ..._product.toMap(),
      'sale_price_cents': 1900,
      'is_new': true,
    });
    Future<void> show(Product item) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductTile(product: item, onTap: () {}),
        ),
      ),
    );
    await show(product);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('Em promoção'), findsOneWidget);
    await show(Product.fromMap({...product.toMap(), 'is_new': false}));
    expect(find.text('NEW'), findsNothing);
    expect(find.text('Em promoção'), findsOneWidget);
  });
}
