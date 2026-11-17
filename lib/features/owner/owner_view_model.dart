import 'package:flutter/foundation.dart' hide Category;

import '../../core/app_services.dart';
import '../../data/remote/catalog_repository.dart';
import '../../data/remote/photo_repository.dart';
import '../../domain/catalog.dart';
import '../../domain/menu_address.dart';

class OwnerViewModel extends ChangeNotifier {
  OwnerViewModel(
    this.repository, {
    this.restaurant,
    this.table = 'restaurants',
  });
  final CatalogRepository repository;
  final Restaurant? restaurant;
  final String table;
  List<Object> items = [];
  bool busy = false, more = false, _disposed = false;
  int _page = 0;
  String? error;
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> load({bool next = false}) async {
    if (busy || _disposed) {
      return;
    }
    busy = true;
    error = null;
    _notify();
    final page = next ? _page + 1 : 0;
    try {
      final List<Object> data = switch (table) {
        'restaurants' => await repository.restaurants(owned: true, page: page),
        'categories' => await repository.categories(restaurant!.id),
        _ => await repository.products(restaurant!.id, owner: true, page: page),
      };
      if (_disposed) {
        return;
      }
      items = next ? [...items, ...data] : data;
      _page = page;
      more = table != 'categories' && data.length == CatalogRepository.pageSize;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _ImageEdit {
  SelectedPhoto? photo;
  String? uploadedUrl;
  bool changed = false;
}

class EditorViewModel extends ChangeNotifier {
  EditorViewModel(this.repository, this.args, {PhotoRepository? photos})
    : photos = photos ?? PhotoRepository(repository.client);
  final CatalogRepository repository;
  final EditorArgs args;
  final PhotoRepository photos;
  final _cover = _ImageEdit();
  final _logo = _ImageEdit();
  String? status;
  SelectedPhoto? get photo => _cover.photo;
  SelectedPhoto? get logo => _logo.photo;
  String? get logoUrl =>
      _logo.changed ? _logo.uploadedUrl : args.restaurant?.logoUrl;
  String? get photoUrl => _cover.changed
      ? _cover.uploadedUrl
      : (args.table == 'restaurants'
            ? args.restaurant?.imageUrl
            : args.product?.imageUrl);

  Future<bool> selectPhoto({bool logo = false}) async {
    if (busy || _disposed) return false;
    final image = logo ? _logo : _cover;
    busy = true;
    status = logo ? 'Preparando logo…' : 'Escolhendo e preparando foto…';
    error = null;
    notifyListeners();
    try {
      final selected = await photos.pick().timeout(const Duration(seconds: 90));
      if (_disposed || selected == null) return false;
      image.photo = selected;
      image.changed = true;
      image.uploadedUrl = null;
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      busy = false;
      status = null;
      if (!_disposed) notifyListeners();
    }
  }

  void removePhoto({bool logo = false}) {
    if (busy) return;
    final image = logo ? _logo : _cover;
    image.photo = null;
    image.changed = true;
    image.uploadedUrl = null;
    notifyListeners();
  }

  Future<void> _saveImage(Json values, String column, _ImageEdit image) async {
    if (!image.changed) return;
    final photo = image.photo;
    if (photo != null && image.uploadedUrl == null) {
      status = column == 'logo_url' ? 'Enviando logo…' : 'Enviando foto…';
      if (!_disposed) notifyListeners();
      image.uploadedUrl = await photos.upload(photo);
    }
    values[column] = image.uploadedUrl;
  }

  String? _generatedAddress;

  String addressFor(String name) =>
      args.restaurant?.slug ??
      (_generatedAddress ??= MenuAddress.generate(name));
  bool busy = false, _disposed = false;
  String? error;
  List<Category> categories = [];
  Future<void> loadCategories() async {
    busy = true;
    notifyListeners();
    try {
      categories = await repository.categories(args.restaurant!.id);
    } catch (e) {
      error = friendlyError(e);
    } finally {
      busy = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  String? get id => switch (args.table) {
    'restaurants' => args.restaurant?.id,
    'categories' => args.category?.id,
    _ => args.product?.id,
  };
  Future<bool> save({
    required String name,
    required String description,
    required String price,
    required String? categoryId,
    required bool enabled,
    String? salePrice,
    DateTime? flashEndsAt,
    bool isNew = false,
    String? menuAccent,
    String? menuTitle,
  }) async {
    if (busy) {
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final user = repository.client.auth.currentUser;
      if (user == null) {
        throw const FormatException('Entre novamente para salvar.');
      }
      final Json values;
      switch (args.table) {
        case 'restaurants':
          if (Rules.name(name, min: 2) != null) {
            throw const FormatException('Confira o nome do restaurante.');
          }
          if ((menuAccent != null && Rules.menuAccent(menuAccent) == null) ||
              (menuTitle != null && Rules.name(menuTitle) != null)) {
            throw const FormatException(
              'Confira o título e a cor do cardápio.',
            );
          }
          values = {
            'name': name.trim(),
            'slug': addressFor(name),
            'description': description.trim(),
            'published': enabled,
            if (menuAccent != args.restaurant?.menuAccent)
              'menu_accent': Rules.menuAccent(menuAccent ?? ''),
            if (menuTitle != args.restaurant?.menuTitle)
              'menu_title': menuTitle,
            if (id == null) 'owner_id': user.id,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          };
        case 'categories':
          if (Rules.name(name, max: 80) != null) {
            throw const FormatException('Confira o nome da categoria.');
          }
          values = {'name': name.trim(), 'restaurant_id': args.restaurant!.id};
        default:
          final cents = Rules.cents(price);
          if (cents == null || categoryId == null || Rules.name(name) != null) {
            throw const FormatException('Confira nome, categoria e preço.');
          }
          final saleCents = salePrice == null ? null : Rules.cents(salePrice);
          if (salePrice != null && (saleCents == null || saleCents >= cents)) {
            throw const FormatException(
              'Informe um preço promocional menor que o preço normal.',
            );
          }
          final end = saleCents == null ? null : flashEndsAt?.toUtc();
          values = {
            'name': name.trim(),
            'description': description.trim(),
            'price_cents': cents,
            'restaurant_id': args.restaurant!.id,
            'category_id': categoryId,
            'available': enabled,
            if (saleCents != args.product?.salePriceCents)
              'sale_price_cents': saleCents,
            if (end != args.product?.flashEndsAt?.toUtc())
              'flash_ends_at': end?.toIso8601String(),
            if (isNew != (args.product?.isNew ?? false)) 'is_new': isNew,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          };
      }
      if (args.table != 'categories') {
        await _saveImage(values, 'image_url', _cover);
      }
      if (args.table == 'restaurants') {
        await _saveImage(values, 'logo_url', _logo);
      }
      status = 'Salvando…';
      if (!_disposed) notifyListeners();
      await repository.save(args.table, values, id: id);
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      busy = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<bool> delete() async {
    if (busy || id == null) {
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await repository.delete(args.table, id!);
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      busy = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
