import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/catalog.dart';

class CatalogRepository {
  CatalogRepository(this.client);
  final SupabaseClient client;
  static const pageSize = 20;
  Future<List<Restaurant>> restaurants({
    bool owned = false,
    int page = 0,
  }) async {
    var query = client.from('restaurants').select();
    if (owned) {
      final id = client.auth.currentUser?.id;
      if (id == null) {
        throw const AuthException('Entre para gerenciar seu restaurante.');
      }
      query = query.eq('owner_id', id);
    } else {
      query = query.eq('published', true);
    }
    final rows = await query
        .order('name')
        .order('id')
        .range(page * pageSize, (page + 1) * pageSize - 1)
        .timeout(const Duration(seconds: 15));
    return rows.map(Restaurant.fromMap).toList();
  }

  Future<Restaurant> bySlug(String slug) async {
    final row = await client
        .from('restaurants')
        .select()
        .eq('slug', slug)
        .eq('published', true)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));
    if (row == null) {
      throw const FormatException('Cardápio não encontrado ou não publicado.');
    }
    return Restaurant.fromMap(row);
  }

  Future<List<Category>> categories(String restaurantId) async {
    final all = <Category>[];
    for (var offset = 0; ; offset += 200) {
      final rows = await client
          .from('categories')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('position')
          .order('id')
          .range(offset, offset + 199)
          .timeout(const Duration(seconds: 15));
      all.addAll(rows.map(Category.fromMap));
      if (rows.length < 200) {
        return all;
      }
    }
  }

  Future<List<Product>> products(
    String restaurantId, {
    String search = '',
    String? category,
    int page = 0,
    bool owner = false,
  }) async {
    var query = client
        .from('products')
        .select()
        .eq('restaurant_id', restaurantId);
    if (!owner) {
      query = query.eq('available', true);
    }
    if (category != null) {
      query = query.eq('category_id', category);
    }
    if (search.trim().isNotEmpty) {
      query = query.ilike(
        'name',
        '%${search.trim().replaceAll('%', '').replaceAll('_', '')}%',
      );
    }
    final rows = await query
        .order('name')
        .order('id')
        .range(page * pageSize, (page + 1) * pageSize - 1)
        .timeout(const Duration(seconds: 15));
    return rows.map(Product.fromMap).toList();
  }

  Future<void> save(String table, Json values, {String? id}) async {
    if (client.auth.currentUser == null) {
      throw const AuthException('Sua sessão terminou. Entre novamente.');
    }
    if (!['restaurants', 'categories', 'products'].contains(table)) {
      throw ArgumentError('Tabela inválida');
    }
    if (id == null) {
      await client
          .from(table)
          .insert(values)
          .timeout(const Duration(seconds: 15));
    } else {
      await client
          .from(table)
          .update(values)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));
    }
  }

  Future<void> delete(String table, String id) async {
    if (!['restaurants', 'categories', 'products'].contains(table)) {
      throw ArgumentError('Tabela inválida');
    }
    await client
        .from(table)
        .delete()
        .eq('id', id)
        .select()
        .single()
        .timeout(const Duration(seconds: 15));
  }
}

String friendlyError(Object error) {
  if (error is TimeoutException) {
    return 'A conexão demorou demais. Tente novamente.';
  }
  if (error is FormatException) {
    return error.message;
  }
  if (error is AuthException) {
    if (error.message.contains('Invalid login')) {
      return 'E-mail ou senha incorretos.';
    }
    if (error.message.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return 'Não foi possível autenticar. Confira os dados e tente novamente. ${error.message}';
  }
  if (error is PostgrestException) {
    if (error.code == '23505') {
      return 'Este endereço já está em uso. Escolha outro.';
    }
    if (error.code == '23503') {
      return 'Existem produtos nesta categoria. Mova ou exclua os produtos primeiro.';
    }
    if (error.code == '42501') {
      return 'Sem permissão. Entre com a conta do proprietário.';
    }
    return 'Não foi possível acessar os dados. Tente novamente.';
  }
  return 'Não foi possível conectar. Confira sua internet e tente novamente.';
}
