import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simples_qr/data/local/catalog_cache.dart';
import 'package:simples_qr/domain/catalog.dart';

void main() {
  test('SQLite cria schema versionado e persiste cache e favoritos', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    final cache = CatalogCache(
      await SharedPreferences.getInstance(),
      useSqlite: true,
    );
    final db = await DatabaseHelper.instance.database;
    expect(await db.getVersion(), 2);
    expect(identical(db, await DatabaseHelper.instance.database), true);
    await cache.write('teste', 'inicial');
    await cache.write('teste', 'atualizado');
    expect(await cache.read('teste'), 'atualizado');
    const product = Product(
      id: 'test-product',
      restaurantId: 'r',
      categoryId: 'c',
      name: 'Teste',
      priceCents: 150,
    );
    await cache.saveFavorite(product);
    await cache.saveFavorite(product);
    expect(
      (await cache.favorites()).where((p) => p.id == product.id).length,
      1,
    );
    await cache.deleteFavorite(product.id);
    expect((await cache.favorites()).where((p) => p.id == product.id), isEmpty);
    await cache.remove('teste');
    expect(await cache.read('teste'), isNull);
    await db.close();
  });
}
