import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/catalog_repository.dart';
import '../../domain/catalog.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/menu_photo.dart';
import 'owner_view_model.dart';

class OwnerListView extends StatefulWidget {
  const OwnerListView({
    required this.services,
    this.restaurant,
    this.table = 'restaurants',
    super.key,
  });
  final AppServices services;
  final Restaurant? restaurant;
  final String table;
  @override
  State<OwnerListView> createState() => _OwnerListViewState();
}

class _OwnerListViewState extends State<OwnerListView> {
  late final OwnerViewModel _model;
  @override
  void initState() {
    super.initState();
    _model = OwnerViewModel(
      widget.services.repository,
      restaurant: widget.restaurant,
      table: widget.table,
    )..load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _edit([Object? item]) async {
    await Navigator.pushNamed(
      context,
      '/edit',
      arguments: EditorArgs(
        widget.table,
        restaurant: item is Restaurant ? item : widget.restaurant,
        category: item is Category ? item : null,
        product: item is Product ? item : null,
      ),
    );
    if (mounted) {
      await _model.load();
    }
  }

  Future<void> _logout() async {
    try {
      await widget.services.client!.auth.signOut(scope: SignOutScope.local);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.table) {
      'restaurants' => 'Meus restaurantes',
      'categories' => 'Categorias',
      _ => 'Produtos',
    };
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (widget.table == 'restaurants')
              IconButton(
                tooltip: 'Sair da conta',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _model.busy ? null : () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
        body: ContentWidth(
          child: RefreshIndicator(
            onRefresh: () => _model.load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _model.items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      if (widget.restaurant != null)
                        SectionTitle(widget.restaurant!.name),
                      if (_model.error != null) ...[
                        Notice(_model.error!, error: true),
                        TextButton(
                          onPressed: () => _model.load(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                      if (_model.busy) const LinearProgressIndicator(),
                      if (!_model.busy &&
                          _model.items.isEmpty &&
                          _model.error == null)
                        const EmptyState(
                          'Nada cadastrado ainda. Toque em Adicionar para começar.',
                        ),
                    ],
                  );
                }
                if (index > _model.items.length) {
                  return _model.more
                      ? LoadMore(
                          busy: _model.busy,
                          onPressed: () => _model.load(next: true),
                        )
                      : const SizedBox.shrink();
                }
                final item = _model.items[index - 1];
                if (item is Restaurant) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.imageUrl != null) ...[
                            MenuPhoto(url: item.imageUrl, label: item.name),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            item.published
                                ? 'Publicado • ${item.slug}'
                                : 'Rascunho • ${item.slug}',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _edit(item),
                                child: const Text('Editar restaurante'),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/categories',
                                  arguments: AdminArgs(item),
                                ),
                                child: const Text('Categorias'),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/products',
                                  arguments: AdminArgs(item),
                                ),
                                child: const Text('Produtos'),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/qr',
                                  arguments: AdminArgs(item),
                                ),
                                child: const Text('QR code'),
                              ),
                              if (item.published)
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/menu',
                                    arguments: MenuArgs(item.slug),
                                  ),
                                  child: const Text('Ver cardápio'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (item is Category) {
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _edit(item),
                    ),
                  );
                }
                return ProductTile(
                  product: item as Product,
                  onTap: () => _edit(item),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class EditorView extends StatefulWidget {
  const EditorView({required this.services, required this.args, super.key});
  final AppServices services;
  final EditorArgs args;
  @override
  State<EditorView> createState() => _EditorViewState();
}

enum _PromotionMode { none, regular, flash }

class _EditorViewState extends State<EditorView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _description = TextEditingController(),
      _price = TextEditingController(),
      _salePrice = TextEditingController(),
      _flashMinutes = TextEditingController(),
      _menuTitle = TextEditingController(),
      _menuAccent = TextEditingController();
  late final EditorViewModel _model;
  _PromotionMode _promotion = _PromotionMode.none;
  DateTime? _flashEndsAt;
  String? _category;
  bool _enabled = false, _isNew = false, _dirty = false, _leaving = false;
  @override
  void initState() {
    super.initState();
    final a = widget.args;
    _model = EditorViewModel(widget.services.repository, a);
    if (a.table == 'restaurants') {
      _name.text = a.restaurant?.name ?? '';
      _description.text = a.restaurant?.description ?? '';
      _enabled = a.restaurant?.published ?? false;
      _menuTitle.text = a.restaurant?.menuTitle ?? '';
      _menuAccent.text = a.restaurant?.menuAccent ?? '';
    } else if (a.table == 'categories') {
      _name.text = a.category?.name ?? '';
    } else {
      _name.text = a.product?.name ?? '';
      _description.text = a.product?.description ?? '';
      _price.text = a.product == null
          ? ''
          : (a.product!.priceCents / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ',');
      _category = a.product?.categoryId;
      _enabled = a.product?.available ?? true;
      _isNew = a.product?.isNew ?? false;
      _flashEndsAt = a.product?.flashEndsAt;
      if (a.product?.salePriceCents case final sale?) {
        _salePrice.text = Product.formatPrice(sale).substring(3);
        _promotion = _flashEndsAt == null
            ? _PromotionMode.regular
            : _PromotionMode.flash;
      }
      _model.loadCategories();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _salePrice.dispose();
    _flashMinutes.dispose();
    _menuTitle.dispose();
    _menuAccent.dispose();
    super.dispose();
  }

  void _finish() {
    setState(() {
      _dirty = false;
      _leaving = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final isFlash = _promotion == _PromotionMode.flash;
    final minutes = isFlash ? int.tryParse(_flashMinutes.text.trim()) : null;
    final title = _menuTitle.text.trim();
    final ok = await _model.save(
      name: _name.text,
      description: _description.text,
      price: _price.text,
      categoryId: _category,
      enabled: _enabled,
      salePrice: _promotion == _PromotionMode.none ? null : _salePrice.text,
      flashEndsAt: isFlash ? _flashEndsAt : null,
      flashDuration: minutes == null ? null : Duration(minutes: minutes),
      isNew: _isNew,
      menuAccent: Rules.menuAccent(_menuAccent.text),
      menuTitle: title.isEmpty ? null : title,
    );
    if (ok && mounted) {
      _finish();
    }
  }

  Future<void> _delete() async {
    final warning = widget.args.table == 'restaurants'
        ? 'O restaurante, suas categorias e produtos serão excluídos permanentemente.'
        : 'Este registro será excluído permanentemente.';
    if (!await confirm(context, 'Excluir registro?', warning) || !mounted) {
      return;
    }
    final ok = await _model.delete();
    if (ok && mounted) {
      _finish();
    }
  }

  Widget _imageEditor({required String label, bool logo = false}) {
    final photo = logo ? _model.logo : _model.photo;
    final url = logo ? _model.logoUrl : _model.photoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photo != null || url != null)
          SizedBox(
            width: logo ? 96 : double.infinity,
            child: MenuPhoto(
              bytes: photo?.bytes,
              url: url,
              width: logo ? 96 : null,
              height: logo ? 96 : 180,
              fit: logo ? BoxFit.contain : BoxFit.cover,
              label: 'Prévia de ${label.toLowerCase()}',
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _model.busy
                  ? null
                  : () async {
                      final changed = await _model.selectPhoto(logo: logo);
                      if (mounted && changed) setState(() => _dirty = true);
                    },
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Escolher ${label.toLowerCase()}'),
            ),
            if (photo != null || url != null)
              TextButton(
                onPressed: _model.busy
                    ? null
                    : () {
                        _model.removePhoto(logo: logo);
                        setState(() => _dirty = true);
                      },
                child: Text('Remover ${label.toLowerCase()}'),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _brandingFields() {
    const palettes = {
      'Terracota': '',
      'Oliva': '#50642A',
      'Vinho': '#852545',
      'Azul': '#245D81',
    };
    return [
      const SectionTitle('Personalizar cardápio'),
      _imageEditor(label: 'Logo', logo: true),
      const SizedBox(height: 12),
      TextFormField(
        controller: _menuTitle,
        enabled: !_model.busy,
        maxLength: 120,
        decoration: const InputDecoration(
          labelText: 'Título do cardápio (opcional)',
          hintText: 'Nome do restaurante',
          border: OutlineInputBorder(),
        ),
      ),
      Text('Cor do cardápio', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      ValueListenableBuilder(
        valueListenable: _menuAccent,
        builder: (context, value, _) => Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final palette in palettes.entries)
              ChoiceChip(
                label: Text(palette.key),
                avatar: CircleAvatar(
                  backgroundColor: AppTheme.menuSeed(palette.value),
                ),
                showCheckmark: false,
                selected: value.text.trim().toUpperCase() == palette.value,
                onSelected: _model.busy
                    ? null
                    : (_) => setState(() {
                        _menuAccent.text = palette.value;
                        _dirty = true;
                      }),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _menuAccent,
        enabled: !_model.busy,
        textCapitalization: TextCapitalization.characters,
        validator: (value) {
          final hex = value?.trim() ?? '';
          return hex.isEmpty || Rules.menuAccent(hex) != null
              ? null
              : 'Use uma cor no formato #A63D24.';
        },
        decoration: const InputDecoration(
          labelText: 'Código hexadecimal (opcional)',
          hintText: '#A63D24',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  List<Widget> _promotionFields() {
    final endsAt = _flashEndsAt;
    final localizations = MaterialLocalizations.of(context);
    final localEnd = endsAt?.toLocal();
    final existingDeadline = localEnd == null
        ? 'A contagem começa ao salvar.'
        : endsAt!.isAfter(DateTime.now())
        ? 'Término atual: ${localizations.formatShortDate(localEnd)} às '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localEnd), alwaysUse24HourFormat: true)}.'
        : 'Promoção encerrada. Informe outra duração para reativar.';
    return [
      const SectionTitle('Promoções e novidades'),
      DropdownButtonFormField<_PromotionMode>(
        initialValue: _promotion,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Tipo de promoção',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(
            value: _PromotionMode.none,
            child: Text('Sem promoção'),
          ),
          DropdownMenuItem(
            value: _PromotionMode.regular,
            child: Text('Promoção'),
          ),
          DropdownMenuItem(
            value: _PromotionMode.flash,
            child: Text('Promoção-relâmpago'),
          ),
        ],
        onChanged: _model.busy
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _promotion = value;
                  _dirty = true;
                });
              },
      ),
      if (_promotion != _PromotionMode.none) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _salePrice,
          enabled: !_model.busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final sale = Rules.cents(value ?? '');
            final normal = Rules.cents(_price.text);
            return sale != null && normal != null && sale < normal
                ? null
                : 'Informe um valor menor que o preço normal.';
          },
          decoration: const InputDecoration(
            labelText: 'Preço promocional',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      if (_promotion == _PromotionMode.flash) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _flashMinutes,
          enabled: !_model.busy,
          keyboardType: TextInputType.number,
          onChanged: (_) => _model.resetFlashDeadline(),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty && endsAt != null) return null;
            final minutes = int.tryParse(text);
            return minutes != null && minutes >= 1 && minutes <= 525600
                ? null
                : 'Informe uma duração de 1 a 525.600 minutos.';
          },
          decoration: InputDecoration(
            labelText: endsAt == null
                ? 'Duração da oferta em minutos'
                : 'Nova duração em minutos (opcional)',
            hintText: 'Ex.: 60',
            helperText: existingDeadline,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Mostrar selo NEW'),
        value: _isNew,
        onChanged: _model.busy
            ? null
            : (value) => setState(() {
                _isNew = value;
                _dirty = true;
              }),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.args.table;
    final type = table == 'restaurants'
        ? 'restaurante'
        : table == 'categories'
        ? 'categoria'
        : 'produto';
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => PopScope(
        canPop: _leaving || (!_dirty && !_model.busy),
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || _model.busy) {
            return;
          }
          if (await confirm(
                context,
                'Descartar alterações?',
                'As alterações não salvas serão perdidas.',
              ) &&
              mounted) {
            _finish();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('${_model.id == null ? 'Adicionar' : 'Editar'} $type'),
          ),
          body: ContentWidth(
            child: Form(
              key: _form,
              onChanged: () {
                if (!_dirty) {
                  setState(() => _dirty = true);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      enabled: !_model.busy,
                      validator: (v) => Rules.name(
                        v,
                        min: table == 'restaurants' ? 2 : 1,
                        max: table == 'categories' ? 80 : 120,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (table != 'categories') ...[
                      _imageEditor(
                        label: table == 'restaurants' ? 'Foto de capa' : 'Foto',
                      ),
                      const Text(
                        'Foto opcional • JPG, PNG ou WebP • até 5 MB após otimização',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        enabled: !_model.busy,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: table == 'products'
                              ? 'Descrição e ingredientes'
                              : 'Descrição',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (table == 'products') ...[
                      DropdownButtonFormField<String>(
                        initialValue:
                            _model.categories.any((c) => c.id == _category)
                            ? _category
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: _model.categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: _model.busy
                            ? null
                            : (v) => setState(() {
                                _category = v;
                                _dirty = true;
                              }),
                        validator: (v) =>
                            v == null ? 'Escolha uma categoria.' : null,
                      ),
                      if (!_model.busy && _model.categories.isEmpty)
                        const Notice(
                          'Cadastre uma categoria antes de adicionar produtos.',
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _price,
                        enabled: !_model.busy,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => Rules.cents(v ?? '') == null
                            ? 'Informe um preço válido. Exemplo: 25,90.'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Preço em reais',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      ..._promotionFields(),
                    ],
                    if (table == 'restaurants') ..._brandingFields(),
                    if (table != 'categories')
                      SwitchListTile(
                        title: Text(
                          table == 'restaurants'
                              ? 'Publicar cardápio'
                              : 'Produto disponível',
                        ),
                        value: _enabled,
                        onChanged: _model.busy
                            ? null
                            : (v) => setState(() {
                                _enabled = v;
                                _dirty = true;
                              }),
                      ),
                    if (_model.error != null)
                      Notice(_model.error!, error: true),
                    if (_model.busy && _model.status != null) ...[
                      const LinearProgressIndicator(),
                      Text(_model.status!),
                    ],
                    const SizedBox(height: 20),
                    BusyButton(
                      label: 'Salvar',
                      busy: _model.busy,
                      onPressed: _save,
                    ),
                    if (_model.id != null)
                      TextButton.icon(
                        onPressed: _model.busy ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Excluir $type'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
