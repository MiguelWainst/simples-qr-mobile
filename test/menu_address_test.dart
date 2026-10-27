import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:simples_qr/core/app_services.dart';
import 'package:simples_qr/data/remote/catalog_repository.dart';
import 'package:simples_qr/domain/catalog.dart';
import 'package:simples_qr/domain/menu_address.dart';
import 'package:simples_qr/features/owner/owner_view_model.dart';

void main() {
  test('Nome livre gera endereço válido mesmo com acentos e símbolos', () {
    final address = MenuAddress.generate('Café & Pão do Miguel!');
    expect(address, startsWith('cafe-pao-do-miguel-'));
    expect(Rules.slug(address), isNull);
    expect(Rules.slug(MenuAddress.generate('🍕🍕')), isNull);
    expect(
      Rules.slug(MenuAddress.generate(List.filled(120, 'a').join())),
      isNull,
    );
    expect(MenuAddress.generate('Café'), isNot(MenuAddress.generate('Café')));
  });

  test(
    'Renomear restaurante preserva o link existente e tentativas de salvar',
    () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-key',
      );
      final repository = CatalogRepository(client);
      const restaurant = Restaurant(
        id: 'r',
        ownerId: 'u',
        name: 'Antigo',
        slug: 'link-que-ja-foi-impresso',
      );
      final edit = EditorViewModel(
        repository,
        const EditorArgs('restaurants', restaurant: restaurant),
      );
      expect(edit.addressFor('Novo nome'), restaurant.slug);
      final create = EditorViewModel(
        repository,
        const EditorArgs('restaurants'),
      );
      final address = create.addressFor('Primeiro nome');
      expect(create.addressFor('Outro nome'), address);
      edit.dispose();
      create.dispose();
      await client.dispose();
    },
  );
}
