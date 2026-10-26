import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/app_services.dart';
import '../../data/remote/catalog_repository.dart';
import '../../domain/catalog.dart';
import '../../shared/widgets/catalog_widgets.dart';

class CatalogHome extends StatefulWidget {
  const CatalogHome({required this.services, super.key});
  final AppServices services;
  @override
  State<CatalogHome> createState() => _CatalogHomeState();
}
class _CatalogHomeState extends State<CatalogHome> {
  final _code = TextEditingController();
  List<Restaurant> _restaurants = [];
  List<String> _history = [];
  bool _busy = false, _more = false;
  int _page = 0;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _code.dispose(); super.dispose(); }
  Future<void> _load({bool next = false}) async {
    setState(() { _busy = true; _error = null; });
    try {
      final history = List<String>.from(jsonDecode(await widget.services.cache.read('history') ?? '[]') as List);
      if (mounted) setState(() => _history = history);
      final page = next ? _page + 1 : 0;
      final data = await widget.services.repository.restaurants(page: page);
      if (mounted) setState(() {
        _restaurants = next ? [..._restaurants, ...data] : data;
        _page = page; _more = data.length == CatalogRepository.pageSize;
      });
    } catch(e) { if (mounted) setState(() => _error = friendlyError(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  void _open() {
    final code = Rules.menuCode(_code.text);
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um código ou link de cardápio válido.')));
      return;
    }
    Navigator.pushNamed(context, '/menu', arguments: MenuArgs(code));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Simples QR'), actions: [
      IconButton(tooltip: 'Favoritos', onPressed: () => Navigator.pushNamed(context, '/favorites'), icon: const Icon(Icons.favorite_border)),
      IconButton(tooltip: 'Configurações de aparência', onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.contrast)),
      IconButton(tooltip: 'Área do proprietário', onPressed: () => Navigator.pushNamed(context, '/owner'), icon: const Icon(Icons.account_circle_outlined)),
    ]),
    body: ContentWidth(child: RefreshIndicator(onRefresh: _load, child: ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _restaurants.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(
            padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.qr_code_2, size: 56),
              const SectionTitle('Escolha seu próximo sabor.'),
              const Text('Leia o QR da mesa ou encontre seu restaurante.'),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () => Navigator.pushNamed(context, '/scanner'),
                icon: const Icon(Icons.qr_code_scanner), label: const Text('Ler QR code')),
            ]))),
          const SizedBox(height: 20),
          TextField(controller: _code, onSubmitted: (_) => _open(),
            decoration: InputDecoration(labelText: 'Código ou link do cardápio',
              border: const OutlineInputBorder(), suffixIcon: IconButton(
                tooltip: 'Abrir cardápio', onPressed: _open, icon: const Icon(Icons.arrow_forward)))),
          if (_history.isNotEmpty) ...[
            const SectionTitle('Consultados recentemente'),
            SizedBox(height: 56, child: ListView.separated(scrollDirection: Axis.horizontal,
              itemCount: _history.length, separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(label: Text(_history[i]),
                avatar: const Icon(Icons.history), onPressed: () => Navigator.pushNamed(context, '/menu', arguments: MenuArgs(_history[i]))))),
          ],
          const SectionTitle('Restaurantes'),
          if (_error != null) ...[Notice(_error!, error: true),
            TextButton(onPressed: _busy ? null : _load, child: const Text('Tentar novamente'))],
          if (_busy) const LinearProgressIndicator(),
          if (!_busy && _restaurants.isEmpty && _error == null)
            const EmptyState('Nenhum restaurante publicado ainda. Entre na área do proprietário para criar o primeiro.'),
        ]);
        if (index > _restaurants.length) return _more
          ? LoadMore(busy: _busy, onPressed: () => _load(next: true)) : const SizedBox(height: 24);
        final r = _restaurants[index - 1];
        return RestaurantTile(restaurant: r, onTap: () => Navigator.pushNamed(context, '/menu', arguments: MenuArgs(r.slug)));
      }))));
}
