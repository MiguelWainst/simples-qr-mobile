import 'package:flutter/material.dart';
import '../../core/app_services.dart';
import '../../data/remote/catalog_repository.dart';
import '../../domain/catalog.dart';
import '../../shared/widgets/catalog_widgets.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({required this.services, super.key});
  final AppServices services;
  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}
class _FavoritesViewState extends State<FavoritesView> {
  List<Product> _items = [];
  String? _error;
  bool _busy = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final items = await widget.services.cache.favorites();
      if (mounted) setState(() { _items = items; _error = null; });
    } catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _remove(Product product) async {
    if (!await confirm(context, 'Remover favorito?', product.name) || !mounted) return;
    try {
      await widget.services.cache.deleteFavorite(product.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Favorito removido.'),
        action: SnackBarAction(label: 'Desfazer', onPressed: () async {
          try { await widget.services.cache.saveFavorite(product); await _load(); }
          catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
        })));
    } catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Favoritos')),
    body: ContentWidth(child: RefreshIndicator(onRefresh: _load, child: ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _items.length + 1, itemBuilder: (context, index) {
        if (index == 0) return Column(children: [
          const Notice('Produtos salvos neste aparelho. Preços e disponibilidade podem ter mudado.'),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Notice(_error!, error: true),
          if (!_busy && _items.isEmpty) const EmptyState('Seus sabores favoritos vão aparecer aqui.', icon: Icons.favorite_border),
        ]);
        final p = _items[index - 1];
        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          ProductTile(product: p, onTap: () async {
            await Navigator.pushNamed(context, '/product', arguments: ProductArgs(p, offline: true));
            await _load();
          }),
          TextButton.icon(onPressed: () => _remove(p), icon: const Icon(Icons.delete_outline), label: const Text('Remover')),
        ]);
      }))));
}
class ProductView extends StatefulWidget {
  const ProductView({required this.services, required this.args, super.key});
  final AppServices services;
  final ProductArgs args;
  @override
  State<ProductView> createState() => _ProductViewState();
}
class _ProductViewState extends State<ProductView> {
  bool _saved = false, _busy = true;
  String? _error;
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    try {
      final items = await widget.services.cache.favorites();
      if (mounted) setState(() => _saved = items.any((p) => p.id == widget.args.product.id));
    } catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _toggle() async {
    final p = widget.args.product;
    if (_saved && !await confirm(context, 'Remover favorito?', p.name)) return;
    if (!mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_saved) { await widget.services.cache.deleteFavorite(p.id); }
      else { await widget.services.cache.saveFavorite(p); }
      if (mounted) {
        final removed = _saved;
        setState(() => _saved = !_saved);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(removed ? 'Favorito removido.' : 'Produto salvo nos favoritos.'),
          action: removed ? SnackBarAction(label: 'Desfazer', onPressed: () async {
            try { await widget.services.cache.saveFavorite(p); await _check(); }
            catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
          }) : null));
      }
    } catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final p = widget.args.product;
    return Scaffold(appBar: AppBar(title: const Text('Detalhes do produto')), body: ContentWidth(
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Container(height: 180, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.restaurant, size: 80)),
        SectionTitle(p.name), PriceLabel(p), const SizedBox(height: 24),
        Text(p.description.isEmpty ? 'Descrição não informada pelo restaurante.' : p.description),
        if (widget.args.offline) const Notice('Cópia salva. Confirme preço, ingredientes e disponibilidade no restaurante.'),
        if (!p.available) const Notice('Produto indisponível no momento.'),
        if (_error != null) Notice(_error!, error: true),
        const SizedBox(height: 24),
        BusyButton(label: _saved ? 'Remover dos favoritos' : 'Salvar nos favoritos', busy: _busy, onPressed: _toggle),
      ])));
  }
}
