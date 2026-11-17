import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:simples_qr/data/remote/photo_repository.dart';
import 'package:simples_qr/data/remote/catalog_repository.dart';
import 'package:simples_qr/domain/catalog.dart';
import 'package:simples_qr/features/auth/auth_view_model.dart';
import 'package:simples_qr/shared/widgets/menu_photo.dart';
import 'package:simples_qr/core/app_services.dart';
import 'package:simples_qr/features/owner/owner_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'falha de upload preserva foto; retry salva sem duplicar upload concluído',
    () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'access_token': 'test-token',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'u',
                'aud': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
          ),
        ),
      );
      await client.auth.signInWithPassword(
        email: 'user@example.com',
        password: 'password123',
      );
      final repository = _Catalog(client);
      final photos = _Photos(client);
      final model = EditorViewModel(
        repository,
        const EditorArgs('restaurants'),
        photos: photos,
      );
      expect(await model.selectPhoto(), isTrue);
      Future<bool> save() => model.save(
        name: 'Restaurante',
        description: '',
        price: '',
        categoryId: null,
        enabled: true,
      );
      expect(await save(), isFalse);
      expect(model.busy, isFalse);
      expect(model.photo, isNotNull);
      expect(repository.saved, isNull);
      photos.fail = false;
      repository.fail = true;
      expect(await save(), isFalse);
      final uploads = photos.uploads;
      repository.fail = false;
      expect(await save(), isTrue);
      expect(photos.uploads, uploads);
      expect(repository.saved?['image_url'], 'https://example.com/photo.jpg');
      model.removePhoto();
      expect(await save(), isTrue);
      expect(repository.saved?['image_url'], isNull);
      model.dispose();
      await client.dispose();
    },
  );

  test('foto valida conteúdo e limite antes de enviar', () {
    expect(
      SelectedPhoto.fromBytes(Uint8List.fromList([255, 216, 255, 0]))
          .contentType,
      'image/jpeg',
    );
    expect(
      () => SelectedPhoto.fromBytes(Uint8List(SelectedPhoto.maxBytes + 1)),
      throwsFormatException,
    );
    expect(
      () => SelectedPhoto.fromBytes(
        Uint8List.fromList(utf8.encode('<svg></svg>')),
      ),
      throwsFormatException,
    );
    expect(() => SelectedPhoto.fromBytes(Uint8List(0)), throwsFormatException);
  });

  test('cache antigo continua legível e foto permanece no novo cache', () {
    final old = {
      'id': 'p',
      'restaurant_id': 'r',
      'category_id': 'c',
      'name': 'Produto',
      'price_cents': 1200,
    };
    expect(Product.fromMap(old).imageUrl, isNull);
    final product = Product.fromMap({
      ...old,
      'image_url': 'https://example.com/foto.jpg',
    });
    expect(Product.fromJson(product.toJson()).imageUrl, product.imageUrl);
    const restaurant = Restaurant(
      id: 'r',
      ownerId: 'u',
      name: 'Restaurante',
      slug: 'teste',
      imageUrl: 'https://example.com/capa.jpg',
    );
    expect(
      Restaurant.fromJson(restaurant.toJson()).imageUrl,
      restaurant.imageUrl,
    );
  });

  test(
    'cadastro pendente permite reenvio e impede cliques duplicados',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/signup')) {
            return http.Response(
              jsonEncode({
                'id': 'u',
                'aud': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-01-01T00:00:00Z',
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
      final model = AuthViewModel(client);
      expect(
        await model.submit(
          AuthMode.register,
          ' usuario@example.com ',
          'password123',
        ),
        isFalse,
      );
      expect(model.needsConfirmation, isTrue);
      expect(model.resendSeconds, 60);
      await model.resendConfirmation('usuario@example.com');
      expect(requests.length, 1);
      model.resendSeconds = 0;
      await model.resendConfirmation('usuario@example.com');
      expect(requests.last.url.path, '/auth/v1/resend');
      expect(jsonDecode(requests.last.body)['type'], 'signup');
      expect(model.busy, isFalse);
      model.dispose();
      await client.dispose();
    },
  );

  test('falha SMTP encerra espera e mostra mensagem útil', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'email_address_not_authorized',
            'msg': 'Email address not authorized',
          }),
          400,
        ),
      ),
    );
    final model = AuthViewModel(client);
    expect(
      await model.submit(
        AuthMode.register,
        'usuario@example.com',
        'password123',
      ),
      isFalse,
    );
    expect(model.busy, isFalse);
    expect(model.error, contains('serviço de e-mail'));
    expect(model.message, isNull);
    model.dispose();
    await client.dispose();
  });

  test('erro de rede não expõe URL técnica nem acusa senha', () {
    final message = friendlyError(
      const AuthException(
        'ClientException: Failed to fetch, uri=https://example.com/signup',
      ),
    );
    expect(message, contains('conectar'));
    expect(message, isNot(contains('https://')));
  });

  testWidgets('imagem inválida exibe alternativa sem quebrar a tela', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MenuPhoto(bytes: Uint8List.fromList([1, 2, 3]))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Catalog extends CatalogRepository {
  _Catalog(super.client);
  Json? saved;
  bool fail = false;
  @override
  Future<void> save(String table, Json values, {String? id}) async {
    if (fail) throw const FormatException('Falha ao salvar');
    saved = values;
  }
}

class _Photos extends PhotoRepository {
  _Photos(super.client);
  bool fail = true;
  int uploads = 0;
  @override
  Future<SelectedPhoto?> pick() async =>
      SelectedPhoto.fromBytes(Uint8List.fromList([255, 216, 255, 0]));
  @override
  Future<String> upload(SelectedPhoto photo) async {
    uploads++;
    if (fail) throw const FormatException('Falha no envio');
    return 'https://example.com/photo.jpg';
  }
}
