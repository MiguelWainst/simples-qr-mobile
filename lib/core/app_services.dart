import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/catalog_cache.dart';
import '../data/remote/catalog_repository.dart';
import '../domain/catalog.dart';

class AppServices {
  AppServices({required this.cache, this.client});
  final CatalogCache cache;
  final SupabaseClient? client;
  CatalogRepository get repository {
    if (client == null) throw const FormatException('Configure a conexão com o Supabase para consultar os cardápios.');
    return CatalogRepository(client!);
  }
}
class MenuArgs {
  const MenuArgs(this.slug);
  final String slug;
}
class ProductArgs {
  const ProductArgs(this.product, {this.offline = false});
  final Product product;
  final bool offline;
}
class AdminArgs {
  const AdminArgs(this.restaurant);
  final Restaurant restaurant;
}
class EditorArgs {
  const EditorArgs(this.table, {this.restaurant, this.category, this.product});
  final String table;
  final Restaurant? restaurant;
  final Category? category;
  final Product? product;
}
