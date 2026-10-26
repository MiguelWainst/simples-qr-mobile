import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:simples_qr/domain/catalog.dart';
import 'package:simples_qr/data/local/catalog_cache.dart';
import 'package:simples_qr/data/remote/catalog_repository.dart';
import 'package:simples_qr/features/catalog/catalog_view_model.dart';

const product = Product(id: 'p', restaurantId: 'r', categoryId: 'c',
  name: 'Café', description: 'Café coado', priceCents: 1290);
const restaurant = Restaurant(id: 'r', ownerId: 'u', name: 'Café da Vila',
  slug: 'cafe-da-vila', published: true);
class FakeRepository extends CatalogRepository {
  FakeRepository() : super(SupabaseClient('https://example.supabase.co', 'public-key'));
  bool fail = false, unpublished = false;
  @override
  Future<Restaurant> bySlug(String slug) async {
    if (unpublished) throw const FormatException('Cardápio não encontrado ou não publicado.');
    if (fail) throw TimeoutException('offline');
    return restaurant;
  }
  @override
  Future<List<Category>> categories(String restaurantId) async => [
    const Category(id: 'c', restaurantId: 'r', name: 'Bebidas')];
  @override
  Future<List<Product>> products(String restaurantId, {String search = '', String? category,
    int page = 0, bool owner = false}) async => search == 'nada' ? [] : [product];
}
void main() {
  test('Converte preço em centavos sem arredondamento de entrada inválida', () {
    expect(Rules.cents('12,90'), 1290);
    expect(Rules.cents('0.10'), 10);
    expect(Rules.cents('12.9'), 1290);
    expect(Rules.cents('-1'), isNull);
    expect(Rules.cents('1,999'), isNull);
    expect(Rules.cents('abc'), isNull);
    expect(Rules.cents('99999999'), isNull);
  });
  test('QR aceita slug e link, rejeita conteúdo arbitrário', () {
    expect(Rules.menuCode('cafe-da-vila'), 'cafe-da-vila');
    expect(Rules.menuCode('https://menu.example/?menu=cafe-da-vila'), 'cafe-da-vila');
    expect(Rules.menuCode('https://menu.example/#/?menu=cafe-da-vila'), 'cafe-da-vila');
    expect(Rules.menuCode('javascript:alert(1)'), isNull);
    expect(Rules.menuCode('https://example.com'), isNull);
  });
  test('DTOs preservam valores entre Map e JSON', () {
    expect(Product.fromJson(product.toJson()).toMap(), product.toMap());
    expect(Restaurant.fromJson(restaurant.toJson()).toMap(), restaurant.toMap());
    const category = Category(id: 'c', restaurantId: 'r', name: 'Bebidas');
    expect(Category.fromJson(category.toJson()).toMap(), category.toMap());
    expect(product.price, 'R\$ 12,90');
  });
  test('Valida e-mail, senha e endereço', () {
    expect(Rules.email('miguel@example.com'), isNull);
    expect(Rules.email('invalido'), isNotNull);
    expect(Rules.password('1234567'), isNotNull);
    expect(Rules.slug('Cafe com espaco'), isNotNull);
    expect(Rules.slug('cafe-da-vila'), isNull);
  });
  late CatalogCache cache;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = CatalogCache(await SharedPreferences.getInstance(), useSqlite: false);
  });
  test('Favoritos persistem, atualizam sem duplicação e podem ser removidos', () async {
    await cache.saveFavorite(product);
    await cache.saveFavorite(product);
    final reopened = CatalogCache(await SharedPreferences.getInstance(), useSqlite: false);
    expect((await reopened.favorites()).length, 1);
    await reopened.deleteFavorite(product.id);
    expect(await cache.favorites(), isEmpty);
    await cache.saveFavorite(product);
    expect((await reopened.favorites()).single.name, 'Café');
  });
  test('Cache permite criar, atualizar, ler e excluir', () async {
    await cache.write('menu', 'primeiro');
    await cache.write('menu', 'atualizado');
    expect(await cache.read('menu'), 'atualizado');
    await cache.remove('menu');
    expect(await cache.read('menu'), isNull);
  });
  test('Cardápio carregado continua disponível offline', () async {
    final repo = FakeRepository();
    final model = CatalogViewModel(repo, cache, restaurant.slug);
    await model.load();
    expect(model.products.single.name, 'Café');
    expect(model.offline, false);
    repo.fail = true;
    await model.load();
    expect(model.offline, true);
    expect(model.products.single.priceCents, 1290);
    expect(model.syncedAt, isNotNull);
    model.dispose();
    await repo.client.dispose();
  });
  test('Cardápio retirado do ar não reaparece a partir do cache online', () async {
    final repo = FakeRepository();
    final model = CatalogViewModel(repo, cache, restaurant.slug);
    await model.load();
    repo.unpublished = true;
    await model.load();
    expect(model.products, isEmpty);
    expect(await cache.read(restaurant.slug), isNull);
    expect(model.error, isNotNull);
    model.dispose();
    await repo.client.dispose();
  });
  test('Sem rede e sem cache apresenta erro recuperável', () async {
    final repo = FakeRepository()..fail = true;
    final model = CatalogViewModel(repo, cache, restaurant.slug);
    await model.load();
    expect(model.busy, false);
    expect(model.error, isNotNull);
    repo.fail = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.products, isNotEmpty);
    model.dispose();
    await repo.client.dispose();
  });
}
