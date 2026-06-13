import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';

/// Frosted-glass surface. Uses a real backdrop blur on capable devices and
/// degrades to a flat translucent fill on low-end ones — a long chat list of
/// per-bubble BackdropFilters is expensive on budget phones. One place to
/// tune the look/perf tradeoff for bubbles, the app bar, dividers and input.
class Glass extends StatelessWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final Border? border;
  final double sigma;
  final List<BoxShadow>? boxShadow;

  const Glass({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.border,
    this.sigma = 9,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final lowEnd = context.select((AppBloc b) => b.isLowEndDevice);

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        // Opaque-up the fill when we can't blur, so text stays readable.
        color: lowEnd ? _solidify(color) : color,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (lowEnd) {
      return ClipRRect(borderRadius: borderRadius, child: decorated);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: decorated,
      ),
    );
  }

  /// Pushes a translucent fill toward opaque so it reads without the blur
  /// behind it doing the work.
  Color _solidify(Color c) {
    final a = c.a;
    if (a >= 0.85) return c;
    return c.withValues(alpha: (a + 0.4).clamp(0.0, 1.0));
  }
}
