import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../../data/local/catalog_cache.dart';
import '../../data/remote/catalog_repository.dart';
import '../../domain/catalog.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this.repository, this.cache, this.slug);
  final CatalogRepository repository;
  final CatalogCache cache;
  final String slug;
  Restaurant? restaurant;
  List<Category> categories = [];
  List<Product> products = [];
  String search = '';
  String? category;
  String? error;
  String? cacheWarning;
  DateTime? syncedAt;
  bool offline = false, busy = false, more = false;
  int _page = 0, _generation = 0;
  bool _disposed = false;
  Timer? _debounce;
  void _notify() { if (!_disposed) { notifyListeners(); } }

  Future<void> load({bool next = false}) async {
    if (_disposed || (next && (busy || !more))) { return; }
    final generation = ++_generation;
    busy = true; error = null; cacheWarning = null;
    _notify();
    final page = next ? _page + 1 : 0;
    try {
      final r = await repository.bySlug(slug);
      final c = await repository.categories(r.id);
      final p = await repository.products(r.id, search: search, category: category, page: page);
      if (_disposed || generation != _generation) { return; }
      restaurant = r; categories = c;
      products = next ? [...products, ...p] : p;
      _page = page; more = p.length == CatalogRepository.pageSize;
      offline = false; syncedAt = DateTime.now();
      // Cache only public, unfiltered data; never persist private owner catalogs.
      if (search.isEmpty && category == null) {
        try {
          await cache.write(slug, jsonEncode({'restaurant': r.toMap(),
            'categories': c.map((e) => e.toMap()).toList(),
            'products': products.map((e) => e.toMap()).toList(),
            'saved_at': syncedAt!.toIso8601String(), 'partial': more}));
          final history = List<String>.from(jsonDecode(await cache.read('history') ?? '[]') as List);
          history.remove(slug); history.insert(0, slug);
          await cache.write('history', jsonEncode(history.take(30).toList()));
        } catch (_) { cacheWarning = 'Cardápio carregado, mas não foi possível salvar offline.'; }
      }
    } catch (e) {
      if (_disposed || generation != _generation) { return; }
      if (e is FormatException) {
        await cache.remove(slug);
        products = []; restaurant = null;
        error = friendlyError(e);
      } else if (!next) {
        try {
          final saved = await cache.read(slug);
          if (saved == null) {
            products = []; error = friendlyError(e);
          } else {
            final data = jsonDecode(saved) as Json;
            restaurant = Restaurant.fromMap(Map<String, dynamic>.from(data['restaurant'] as Map));
            categories = (data['categories'] as List).map((e) => Category.fromMap(Map<String, dynamic>.from(e as Map))).toList();
            products = (data['products'] as List).map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
              .where((p) => p.name.toLowerCase().contains(search.toLowerCase()) && (category == null || p.categoryId == category)).toList();
            syncedAt = DateTime.tryParse(data['saved_at'] as String);
            offline = true; more = false;
            cacheWarning = 'Cópia salva: preços e disponibilidade podem ter mudado.'
              '${data['partial'] == true ? ' Apenas os produtos já carregados estão disponíveis.' : ''}';
          }
        } catch (_) { products = []; error = 'Não foi possível ler o cardápio salvo. Conecte-se e tente novamente.'; }
      } else {
        error = friendlyError(e);
      }
    } finally {
      if (!_disposed && generation == _generation) { busy = false; _notify(); }
    }
  }
  void setSearch(String value) {
    search = value;
    _generation++; // Ignore responses from the previous search immediately.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => load());
  }
  void setCategory(String? value) { category = value; _debounce?.cancel(); load(); }
  @override
  void dispose() { _disposed = true; _generation++; _debounce?.cancel(); super.dispose(); }
}
