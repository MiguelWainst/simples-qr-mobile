import 'package:flutter/material.dart';

import '../../domain/catalog.dart';
import 'menu_photo.dart';
import 'product_offer.dart';

class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: child,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.message, {
    this.icon = Icons.restaurant_menu,
    super.key,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class BusyButton extends StatelessWidget {
  const BusyButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    super.key,
  });
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onTap, super.key});
  final Product product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuPhoto(
              url: product.imageUrl,
              width: 76,
              height: 76,
              label: product.name,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (product.isNew) ...[
                        const SizedBox(width: 6),
                        const NewProductBadge(),
                      ],
                    ],
                  ),
                  if (product.description.isNotEmpty)
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  PriceLabel(product),
                  if (!product.available) const Text('Indisponível'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class RestaurantTile extends StatelessWidget {
  const RestaurantTile({
    required this.restaurant,
    required this.onTap,
    super.key,
  });
  final Restaurant restaurant;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: MenuPhoto(
        url: restaurant.logoUrl ?? restaurant.imageUrl,
        width: 56,
        height: 56,
        label: restaurant.name,
      ),
      title: Text(restaurant.name),
      subtitle: Text(
        restaurant.description.isEmpty
            ? restaurant.slug
            : restaurant.description,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class SearchField extends StatelessWidget {
  const SearchField({required this.onChanged, super.key});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: const InputDecoration(
      labelText: 'Buscar produto',
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
  );
}

class LoadMore extends StatelessWidget {
  const LoadMore({required this.busy, required this.onPressed, super.key});
  final bool busy;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: OutlinedButton(
      onPressed: busy ? null : onPressed,
      child: Text(busy ? 'Carregando…' : 'Carregar mais'),
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;
