import 'package:flutter/foundation.dart';
import '../../core/app_services.dart';
import '../../data/remote/catalog_repository.dart';
import '../../domain/catalog.dart';

class OwnerViewModel extends ChangeNotifier {
  OwnerViewModel(this.repository, {this.restaurant, this.table = 'restaurants'});
  final CatalogRepository repository;
  final Restaurant? restaurant;
  final String table;
  List<Object> items = [];
  bool busy = false, more = false, _disposed = false;
  int _page = 0;
  String? error;
  void _notify() { if (!_disposed) notifyListeners(); }
  Future<void> load({bool next = false}) async {
    if (busy || _disposed) return;
    busy = true; error = null; _notify();
    final page = next ? _page + 1 : 0;
    try {
      final List<Object> data = switch(table) {
        'restaurants' => await repository.restaurants(owned: true, page: page),
        'categories' => await repository.categories(restaurant!.id),
        _ => await repository.products(restaurant!.id, owner: true, page: page),
      };
      if (_disposed) return;
      items = next ? [...items, ...data] : data;
      _page = page; more = table != 'categories' && data.length == CatalogRepository.pageSize;
    } catch(e) { error = friendlyError(e); }
    finally { busy = false; _notify(); }
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}

class EditorViewModel extends ChangeNotifier {
  EditorViewModel(this.repository, this.args);
  final CatalogRepository repository;
  final EditorArgs args;
  bool busy = false, _disposed = false;
  String? error;
  List<Category> categories = [];
  Future<void> loadCategories() async {
    busy = true; notifyListeners();
    try { categories = await repository.categories(args.restaurant!.id); }
    catch(e) { error = friendlyError(e); }
    finally { busy = false; if (!_disposed) notifyListeners(); }
  }
  String? get id => switch(args.table) {
    'restaurants' => args.restaurant?.id, 'categories' => args.category?.id, _ => args.product?.id};
  Future<bool> save({required String name, required String description, required String slug,
    required String price, required String? categoryId, required bool enabled}) async {
    if (busy) return false;
    busy = true; error = null; notifyListeners();
    try {
      final user = repository.client.auth.currentUser;
      if (user == null) throw const FormatException('Entre novamente para salvar.');
      final Json values;
      switch(args.table) {
        case 'restaurants':
          if (Rules.name(name, min: 2) != null || Rules.slug(slug) != null) throw const FormatException('Confira nome e endereço.');
          values = {'name': name.trim(), 'slug': slug.trim(), 'description': description.trim(),
            'published': enabled, if (id == null) 'owner_id': user.id,
            'updated_at': DateTime.now().toUtc().toIso8601String()};
        case 'categories':
          if (Rules.name(name, max: 80) != null) throw const FormatException('Confira o nome da categoria.');
          values = {'name': name.trim(), 'restaurant_id': args.restaurant!.id};
        default:
          final cents = Rules.cents(price);
          if (cents == null || categoryId == null || Rules.name(name) != null) {
            throw const FormatException('Confira nome, categoria e preço.');
          }
          values = {'name': name.trim(), 'description': description.trim(), 'price_cents': cents,
            'restaurant_id': args.restaurant!.id, 'category_id': categoryId, 'available': enabled,
            'updated_at': DateTime.now().toUtc().toIso8601String()};
      }
      await repository.save(args.table, values, id: id);
      return true;
    } catch(e) { error = friendlyError(e); return false; }
    finally { busy = false; if (!_disposed) notifyListeners(); }
  }
  Future<bool> delete() async {
    if (busy || id == null) return false;
    busy = true; error = null; notifyListeners();
    try { await repository.delete(args.table, id!); return true; }
    catch(e) { error = friendlyError(e); return false; }
    finally { busy = false; if (!_disposed) notifyListeners(); }
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
