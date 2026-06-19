import 'package:flutter/material.dart';

import 'app_motion.dart';

enum MascotTone {
  info,
  success,
  warning,
  error,
}

class MascotStateCard extends StatelessWidget {
  const MascotStateCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.message,
    this.tone = MascotTone.info,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.child,
    this.imageSize = 140,
    this.centered = true,
  });

  final String imageAsset;
  final String title;
  final String message;
  final MascotTone tone;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final Widget? child;
  final double imageSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);
    final alignment = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return AppEntrance(
      offsetY: 18,
      child: Card(
        color: colors.background,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 560;
              final info = Column(
                crossAxisAlignment: alignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.badge,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _toneLabel(tone),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: centered ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF12243A),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: centered ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF425466),
                          height: 1.4,
                        ),
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 18),
                    child!,
                  ],
                  if (primaryLabel != null || secondaryLabel != null) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (primaryLabel != null)
                          FilledButton(
                            onPressed: onPrimaryPressed,
                            child: Text(primaryLabel!),
                          ),
                        if (secondaryLabel != null)
                          OutlinedButton(
                            onPressed: onSecondaryPressed,
                            child: Text(secondaryLabel!),
                          ),
                      ],
                    ),
                  ],
                ],
              );

              if (vertical) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: alignment,
                  children: [
                    _MascotIllustration(
                      imageAsset: imageAsset,
                      imageSize: imageSize,
                    ),
                    const SizedBox(height: 20),
                    info,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MascotIllustration(
                    imageAsset: imageAsset,
                    imageSize: imageSize,
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: info),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class MascotMessageBanner extends StatelessWidget {
  const MascotMessageBanner({
    super.key,
    required this.title,
    required this.message,
    required this.imageAsset,
    this.tone = MascotTone.info,
  });

  final String title;
  final String message;
  final String imageAsset;
  final MascotTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);

    return AppEntrance(
      offsetY: 10,
      duration: const Duration(milliseconds: 220),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MascotIllustration(
              imageAsset: imageAsset,
              imageSize: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.accent,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF425466),
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotIllustration extends StatelessWidget {
  const _MascotIllustration({
    required this.imageAsset,
    required this.imageSize,
  });

  final String imageAsset;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Image.asset(
          imageAsset,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
          cacheWidth: (imageSize * 2).round(),
          errorBuilder: (context, error, stackTrace) => _MascotFallbackIcon(
            imageSize: imageSize,
          ),
        ),
      ),
    );
  }
}

class _MascotFallbackIcon extends StatelessWidget {
  const _MascotFallbackIcon({required this.imageSize});

  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.calculate_rounded,
        size: imageSize * 0.44,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ToneColors {
  const _ToneColors({
    required this.background,
    required this.badge,
    required this.accent,
    required this.border,
  });

  final Color background;
  final Color badge;
  final Color accent;
  final Color border;
}

_ToneColors _toneColors(BuildContext context, MascotTone tone) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (tone) {
    MascotTone.success => const _ToneColors(
        background: Color(0xFFEAF8F0),
        badge: Color(0xFFD5F2E0),
        accent: Color(0xFF17653A),
        border: Color(0xFF9FD3B1),
      ),
    MascotTone.warning => const _ToneColors(
        background: Color(0xFFFFF5E8),
        badge: Color(0xFFFFE6C0),
        accent: Color(0xFF9A5200),
        border: Color(0xFFF1CB8B),
      ),
    MascotTone.error => _ToneColors(
        background: colorScheme.errorContainer.withValues(alpha: 0.55),
        badge: colorScheme.error.withValues(alpha: 0.10),
        accent: colorScheme.error,
        border: colorScheme.error.withValues(alpha: 0.25),
      ),
    MascotTone.info => const _ToneColors(
        background: Color(0xFFEFF5FF),
        badge: Color(0xFFDCEBFF),
        accent: Color(0xFF1565C0),
        border: Color(0xFFBDD4F5),
      ),
  };
}

String _toneLabel(MascotTone tone) {
  return switch (tone) {
    MascotTone.success => 'Muy bien',
    MascotTone.warning => 'Atencion',
    MascotTone.error => 'Ocurrio un problema',
    MascotTone.info => 'EduCoach te acompaña',
  };
}
