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
    final details = error.message.toLowerCase();
    if (details.contains('failed to fetch') ||
        details.contains('socketexception') ||
        details.contains('network')) {
      return 'Não foi possível conectar ao servidor. Confira sua internet e tente novamente.';
    }
    if (error.code == 'over_email_send_rate_limit' ||
        details.contains('rate limit') ||
        error.statusCode == '429') {
      return 'O limite de envio de e-mails foi atingido. Aguarde alguns minutos antes de tentar novamente.';
    }
    if (error.code == 'email_address_not_authorized' ||
        details.contains('not authorized') ||
        details.contains('error sending') ||
        details.contains('smtp')) {
      return 'O serviço de e-mail não conseguiu enviar a mensagem. O responsável pelo app precisa verificar a configuração de envio.';
    }
    if (error.message.contains('Invalid login')) {
      return 'E-mail ou senha incorretos.';
    }
    if (error.message.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return 'Não foi possível autenticar. Confira os dados e tente novamente.';
  }
  if (error is StorageException) {
    final details = error.message.toLowerCase();
    if (details.contains('bucket') && details.contains('not found')) {
      return 'O armazenamento de fotos ainda não foi ativado. Aplique a configuração de fotos no Supabase.';
    }
    if (details.contains('size') ||
        details.contains('large') ||
        error.statusCode == '413') {
      return 'A foto é muito grande. Escolha uma imagem de até 5 MB.';
    }
    return 'Não foi possível enviar a foto. Sua edição foi mantida; tente salvar novamente.';
  }
  if (error is PostgrestException) {
    if (error.code == 'PGRST204' &&
        [
          'sale_price_cents',
          'flash_ends_at',
          'is_new',
          'logo_url',
          'menu_accent',
          'menu_title',
        ].any(error.message.contains)) {
      return 'Aplique a migração 003 no Supabase para ativar promoções e personalização.';
    }
    if (error.code == 'PGRST204' && error.message.contains('image_url')) {
      return 'As fotos ainda não foram ativadas no banco. Aplique a atualização de fotos no Supabase e tente salvar novamente.';
    }
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
