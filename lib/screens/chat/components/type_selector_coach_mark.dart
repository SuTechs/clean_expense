import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

/// Repeating pulse ring drawn around its child to draw attention to it.
/// Renders just the child when [active] is false.
class PulsingHighlight extends StatefulWidget {
  final bool active;
  final Color color;
  final Widget child;

  const PulsingHighlight({
    super.key,
    required this.active,
    required this.color,
    required this.child,
  });

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight>
    with SingleTickerProviderStateMixin {
  // Constructed eagerly in initState: a lazy `late final` field would be
  // created on first access — which, when the pulse never activates, is
  // dispose(), where ticker creation crashes on a dead element tree.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulsingHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                final t = _controller.value;
                return Transform.scale(
                  scale: 1 + 0.35 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.color.withValues(alpha: (1 - t) * 0.7),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// One-time tooltip pointing at the type-selector trigger, shown above it
/// via a [CompositedTransformFollower]. Dismissed by tapping anywhere.
class TypeSelectorCoachMark extends StatefulWidget {
  final LayerLink link;
  final ChatTheme theme;
  final VoidCallback onDismiss;

  const TypeSelectorCoachMark({
    super.key,
    required this.link,
    required this.theme,
    required this.onDismiss,
  });

  @override
  State<TypeSelectorCoachMark> createState() => _TypeSelectorCoachMarkState();
}

class _TypeSelectorCoachMarkState extends State<TypeSelectorCoachMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Stack(
      children: [
        // Pass-through barrier: a Listener observes the pointer without
        // entering the gesture arena, so the user's first tap BOTH
        // dismisses the hint and still reaches whatever they tapped
        // (an opaque barrier used to swallow it).
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => widget.onDismiss(),
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(-4, -12),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.inputContainerBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        "Tap here to switch between Expense, Income & Invest",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                  ),
                  // Pointer triangle under the bubble, above the trigger.
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: CustomPaint(
                      size: const Size(14, 7),
                      painter: _PointerPainter(color: theme.inputContainerBg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;

  _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
