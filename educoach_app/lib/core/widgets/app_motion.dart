import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    final platform = Theme.of(context).platform;
    final showScrollbar = kIsWeb ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    if (!showScrollbar || details.controller == null) {
      return child;
    }

    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      interactive: true,
      child: child,
    );
  }
}

class AppEntrance extends StatefulWidget {
  const AppEntrance({
    super.key,
    required this.child,
    this.offsetY = 16,
    this.duration = const Duration(milliseconds: 260),
    this.delay = Duration.zero,
  });

  final Widget child;
  final double offsetY;
  final Duration duration;
  final Duration delay;

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      _controller.value = 1;
      return;
    }

    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.lift = 4,
    this.scale = 1.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double lift;
  final double scale;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;
  bool _focused = false;

  bool get _active => widget.enabled && (_hovered || _focused);

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..translateByDouble(0.0, _active ? -widget.lift : 0.0, 0.0, 1.0)
        ..scaleByDouble(_active ? widget.scale : 1.0, _active ? widget.scale : 1.0, 1.0, 1.0),
      child: widget.child,
    );

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: widget.onTap == null ? child : GestureDetector(onTap: widget.onTap, child: child),
      ),
    );
  }
}

class InteractiveParallax extends StatefulWidget {
  const InteractiveParallax({
    super.key,
    required this.child,
    this.maxOffset = 10,
  });

  final Widget child;
  final double maxOffset;

  @override
  State<InteractiveParallax> createState() => _InteractiveParallaxState();
}

class _InteractiveParallaxState extends State<InteractiveParallax> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(event.position);
        final dx = ((local.dx / box.size.width) - 0.5) * widget.maxOffset;
        final dy = ((local.dy / box.size.height) - 0.5) * widget.maxOffset;
        setState(() => _offset = Offset(dx, dy));
      },
      onExit: (_) => setState(() => _offset = Offset.zero),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translateByDouble(_offset.dx, _offset.dy, 0.0, 1.0),
        child: widget.child,
      ),
    );
  }
}
