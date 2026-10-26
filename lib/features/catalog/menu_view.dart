import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../shared/widgets/catalog_widgets.dart';
import 'catalog_view_model.dart';

class MenuView extends StatefulWidget {
  const MenuView({required this.services, required this.slug, super.key});
  final AppServices services;
  final String slug;
  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  CatalogViewModel? _model;
  @override
  void initState() {
    super.initState();
    if (widget.services.client != null) {
      _model = CatalogViewModel(
        widget.services.repository,
        widget.services.cache,
        widget.slug,
      )..load();
    }
  }

  @override
  void dispose() {
    _model?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cardápio')),
        body: const EmptyState(
          'Conecte o aplicativo ao Supabase para consultar este cardápio.',
        ),
      );
    }
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(m.restaurant?.name ?? 'Cardápio'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: m.busy ? null : () => m.load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: ContentWidth(
          child: RefreshIndicator(
            onRefresh: () => m.load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: m.products.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (m.restaurant != null) ...[
                        SectionTitle(m.restaurant!.name),
                        Text(m.restaurant!.description),
                        const SizedBox(height: 20),
                      ],
                      SearchField(onChanged: m.setSearch),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: m.categories.length + 1,
                          itemBuilder: (context, i) {
                            final category = i == 0
                                ? null
                                : m.categories[i - 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category?.name ?? 'Todos'),
                                selected: m.category == category?.id,
                                onSelected: (_) => m.setCategory(category?.id),
                              ),
                            );
                          },
                        ),
                      ),
                      if (m.offline)
                        Notice(
                          'Modo offline • salvo em ${m.syncedAt?.toLocal().toString().split('.').first ?? 'data desconhecida'}',
                        ),
                      if (m.cacheWarning != null) Notice(m.cacheWarning!),
                      if (m.error != null) Notice(m.error!, error: true),
                      if (m.busy) const LinearProgressIndicator(),
                      if (!m.busy && m.products.isEmpty && m.error == null)
                        const EmptyState(
                          'Nenhum produto encontrado. Experimente outra busca ou categoria.',
                        ),
                    ],
                  );
                }
                if (index > m.products.length) {
                  return m.more
                      ? LoadMore(
                          busy: m.busy,
                          onPressed: () => m.load(next: true),
                        )
                      : const SizedBox(height: 24);
                }
                final p = m.products[index - 1];
                return ProductTile(
                  product: p,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/product',
                    arguments: ProductArgs(p, offline: m.offline),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
