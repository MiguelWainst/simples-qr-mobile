import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/catalog.dart';

class PriceLabel extends StatefulWidget {
  const PriceLabel(this.product, {this.now = DateTime.now, super.key});
  final Product product;
  final DateTime Function() now;

  @override
  State<PriceLabel> createState() => _PriceLabelState();
}

class _PriceLabelState extends State<PriceLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(PriceLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.flashEndsAt != widget.product.flashEndsAt ||
        oldWidget.product.salePriceCents != widget.product.salePriceCents ||
        oldWidget.product.priceCents != widget.product.priceCents ||
        oldWidget.now != widget.now) {
      _timer?.cancel();
      _schedule();
    }
  }

  void _schedule() {
    final product = widget.product;
    final end = product.flashEndsAt;
    final now = widget.now();
    if (end == null || product.activeSaleAt(now) == null) return;
    final micros = end.difference(now).inMicroseconds;
    final remainder = micros % Duration.microsecondsPerSecond;
    _timer = Timer(
      Duration(
        microseconds: remainder == 0
            ? Duration.microsecondsPerSecond
            : remainder,
      ),
      () {
        setState(() {});
        _schedule();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final now = widget.now();
    final sale = product.activeSaleAt(now);
    final end = product.flashEndsAt;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final priceStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w800,
    );
    if (sale == null) return Text(product.price, style: priceStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (end == null)
          Text(
            'Em promoção',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          _FlashBadge(remaining: end.difference(now)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              product.price,
              semanticsLabel: 'Preço normal ${product.price}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            Text(
              Product.formatPrice(sale),
              semanticsLabel: 'Preço promocional ${Product.formatPrice(sale)}',
              style: priceStyle?.copyWith(fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }
}

class NewProductBadge extends StatelessWidget {
  const NewProductBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.tertiaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          'NEW',
          semanticsLabel: 'Produto novo',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onTertiaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _FlashBadge extends StatefulWidget {
  const _FlashBadge({required this.remaining});
  final Duration remaining;

  @override
  State<_FlashBadge> createState() => _FlashBadgeState();
}

class _FlashBadgeState extends State<_FlashBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (widget.remaining.inMicroseconds +
            Duration.microsecondsPerSecond -
            1) ~/
        Duration.microsecondsPerSecond;
    final hours = total ~/ 3600;
    final minutes = (total ~/ 60) % 60;
    final seconds = total % 60;
    final time = [
      if (hours > 0) hours,
      minutes,
      seconds,
    ].map((part) => part.toString().padLeft(2, '0')).join(':');
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: const Color(0xFFFFDE66),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF4A3000),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            runSpacing: 2,
            children: [
              ScaleTransition(
                scale: Tween(
                  begin: 1.0,
                  end: 1.25,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(_pulse),
                child: const Icon(
                  Icons.bolt,
                  size: 17,
                  color: Color(0xFF6B3C00),
                ),
              ),
              const Text('Relâmpago'),
              Text(
                time,
                semanticsLabel:
                    'Faltam $hours horas, $minutes minutos e $seconds segundos',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
