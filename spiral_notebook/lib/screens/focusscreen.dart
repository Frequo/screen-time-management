import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        if (appState.isFocusActive || appState.isFocusPaused) {
          return _ImmersiveFocusView(appState: appState);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: theme.cardColor,
                border: Border.all(color: AppPalette.mint, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Put the phone down',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a session, step away from the screen, and convert quiet time into bits.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 188,
                          width: 188,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.mint.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppPalette.mint.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.hourglass_bottom_rounded,
                            color: AppPalette.mint,
                            size: 94,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          appState.formatDuration(
                            appState.selectedFocusTarget * 60,
                          ),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appState.selectedFocusTarget} minute target',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: appState.startFocusSession,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start focus session'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Session target',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: SpiralAppState.focusTargets
                          .map((int target) {
                            final bool selected =
                                target == appState.selectedFocusTarget;
                            return ChoiceChip(
                              label: Text('$target min'),
                              selected: selected,
                              onSelected: (_) =>
                                  appState.setFocusTarget(target),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _FocusFact(
                          label: 'Difficulty',
                          value: appState.difficulty.label,
                        ),
                        _FocusFact(
                          label: 'Reward preview',
                          value: '${appState.currentRewardPreview} bits',
                        ),
                        _FocusFact(
                          label: 'Best run',
                          value: appState.formatDuration(
                            appState.bestSessionSeconds,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (appState.lastFocusResult != null) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Last session',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        appState.lastFocusResult!.label,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${appState.lastFocusResult!.wholeMinutes} minutes completed for ${appState.lastFocusResult!.rewardsEarned} bits.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ImmersiveFocusView extends StatefulWidget {
  const _ImmersiveFocusView({required this.appState});

  final SpiralAppState appState;

  @override
  State<_ImmersiveFocusView> createState() => _ImmersiveFocusViewState();
}

class _ImmersiveFocusViewState extends State<_ImmersiveFocusView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final SpiralAppState appState = widget.appState;
        final bool paused = appState.isFocusPaused;
        final int earnedBits = appState.calculateRewardForSeconds(
          appState.currentSessionSeconds,
        );

        return ColoredBox(
          color: AppPalette.night,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (appState.sessionBackgroundEnabled)
                _AuroraBackground(progress: _controller.value),
              SafeArea(
                bottom: false,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: PopupMenuButton<_FocusMenuAction>(
                          tooltip: 'Session menu',
                          color: AppPalette.nightSurface,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                          ),
                          onSelected: (_FocusMenuAction action) {
                            switch (action) {
                              case _FocusMenuAction.resume:
                                appState.startFocusSession();
                              case _FocusMenuAction.pause:
                                appState.pauseFocusSession();
                              case _FocusMenuAction.finish:
                                _finishSession(context, appState);
                              case _FocusMenuAction.exit:
                                appState.cancelFocusSession();
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<_FocusMenuAction>>[
                              if (paused)
                                const PopupMenuItem<_FocusMenuAction>(
                                  value: _FocusMenuAction.resume,
                                  child: Text(
                                    'Resume session',
                                    style: TextStyle(color: AppPalette.mint),
                                  ),
                                )
                              else
                                const PopupMenuItem<_FocusMenuAction>(
                                  value: _FocusMenuAction.pause,
                                  child: Text(
                                    'Pause session',
                                    style: TextStyle(color: AppPalette.mint),
                                  ),
                                ),
                              const PopupMenuItem<_FocusMenuAction>(
                                value: _FocusMenuAction.finish,
                                child: Text(
                                  'Finish and collect',
                                  style: TextStyle(color: AppPalette.mint),
                                ),
                              ),
                              const PopupMenuItem<_FocusMenuAction>(
                                value: _FocusMenuAction.exit,
                                child: Text(
                                  'Exit session',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ];
                          },
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              paused ? 'Paused' : 'Study session',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              appState.formatDuration(
                                appState.currentSessionSeconds,
                              ),
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              paused
                                  ? 'Timer paused'
                                  : '${appState.remainingTargetSeconds ~/ 60} min until target',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 280,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 12,
                                  value: appState.selectedFocusTarget == 0
                                      ? 0
                                      : (appState.currentSessionSeconds /
                                                (appState.selectedFocusTarget *
                                                    60))
                                            .clamp(0, 1),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppPalette.sun,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '$earnedBits bits ready',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppPalette.sun,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (paused) ...<Widget>[
                              const SizedBox(height: 28),
                              FilledButton.icon(
                                onPressed: appState.startFocusSession,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Resume'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (paused)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraPainter(progress: progress),
      child: const SizedBox.expand(),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF04131F),
          Color(0xFF062338),
          Color(0xFF0A3450),
          Color(0xFF0D4264),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    _paintStars(canvas, size);
    _paintArc(
      canvas,
      size,
      color: AppPalette.mint,
      startFactor: -0.08,
      endFactor: 0.42,
      crestHeight: 0.16,
      bend: -0.24,
      phase: 0.0,
      thickness: 0.115,
      blurSigma: 24,
      alpha: 0.78,
    );
    _paintArc(
      canvas,
      size,
      color: AppPalette.sky,
      startFactor: 0.18,
      endFactor: 0.73,
      crestHeight: 0.2,
      bend: 0.18,
      phase: 0.85,
      thickness: 0.108,
      blurSigma: 22,
      alpha: 0.68,
    );
    _paintArc(
      canvas,
      size,
      color: AppPalette.tangerine,
      startFactor: 0.56,
      endFactor: 1.05,
      crestHeight: 0.12,
      bend: -0.16,
      phase: 1.7,
      thickness: 0.1,
      blurSigma: 24,
      alpha: 0.56,
    );
    _paintArc(
      canvas,
      size,
      color: AppPalette.sun,
      startFactor: 0.2,
      endFactor: 0.66,
      crestHeight: 0.28,
      bend: 0.08,
      phase: 2.4,
      thickness: 0.14,
      blurSigma: 30,
      alpha: 0.18,
    );

    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    final Paint starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8);
    for (int i = 0; i < 90; i++) {
      final double x = ((i * 83.0) % size.width);
      final double y = ((i * 47.0) % (size.height * 0.78));
      final double twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin((progress * math.pi * 2) + i));
      canvas.drawCircle(
        Offset(x, y),
        i % 9 == 0 ? 1.6 : 0.85,
        starPaint..color = Colors.white.withValues(alpha: 0.25 * twinkle),
      );
    }
  }

  void _paintArc(
    Canvas canvas,
    Size size, {
    required Color color,
    required double startFactor,
    required double endFactor,
    required double crestHeight,
    required double bend,
    required double phase,
    required double thickness,
    required double blurSigma,
    required double alpha,
  }) {
    final double time = progress * math.pi * 2;
    final double startX =
        (size.width * startFactor) + (math.sin(time * 0.32 + phase) * 34);
    final double endX =
        (size.width * endFactor) + (math.cos(time * 0.28 + phase) * 30);
    final double startY = -size.height * 0.05;
    final double endY = size.height * (1.02 + 0.02 * math.sin(time + phase));
    final double controlY1 = size.height * crestHeight;
    final double controlY2 = size.height * (0.72 + (bend * 0.08));
    final double controlX1 =
        size.width * (0.28 + bend) + (math.cos(time * 0.42 + phase) * 42);
    final double controlX2 =
        size.width * (0.64 - bend) + (math.sin(time * 0.36 + phase) * 38);

    final Path spine = Path()
      ..moveTo(startX, startY)
      ..cubicTo(controlX1, controlY1, controlX2, controlY2, endX, endY);

    final PathMetric metric = spine.computeMetrics().first;
    final List<Offset> left = <Offset>[];
    final List<Offset> right = <Offset>[];

    for (double d = 0; d <= metric.length; d += 10) {
      final Tangent? tangent = metric.getTangentForOffset(d);
      if (tangent == null) {
        continue;
      }
      final double t = d / metric.length;
      final double sweepDrift =
          math.sin((t * 9.5) + (time * 0.9) + phase) * size.width * 0.008;
      final double halfWidth = math.max(
        size.width * 0.02,
        size.width * thickness * (1 - t * 0.62) + sweepDrift,
      );
      final Offset rawNormal = Offset(-tangent.vector.dy, tangent.vector.dx);
      final double normalDistance = rawNormal.distance;
      final Offset normal = normalDistance == 0
          ? const Offset(0, 0)
          : Offset(
              rawNormal.dx / normalDistance,
              rawNormal.dy / normalDistance,
            );
      left.add(tangent.position + (normal * halfWidth));
      right.add(tangent.position - (normal * halfWidth));
    }

    final Path path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final Offset point in left.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    for (final Offset point in right.reversed) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    final Rect arcRect = Rect.fromLTWH(
      math.min(startX, endX) - size.width * 0.24,
      -size.height * 0.1,
      size.width * 1.3,
      size.height * 1.25,
    );
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.0),
          color.withValues(alpha: alpha * 0.28),
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.34),
          color.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.18, 0.55, 0.82, 1.0],
      ).createShader(arcRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawPath(path, paint);

    final Paint corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.0),
          color.withValues(alpha: alpha * 0.08),
          Colors.white.withValues(alpha: alpha * 0.16),
          color.withValues(alpha: alpha * 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.2, 0.56, 0.8, 1.0],
      ).createShader(arcRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * 0.45);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

enum _FocusMenuAction { resume, pause, finish, exit }

void _finishSession(BuildContext context, SpiralAppState appState) {
  final FocusSessionResult? result = appState.finishFocusSession();
  if (result == null) {
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                result.label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You stayed focused for ${result.wholeMinutes} minutes and earned ${result.rewardsEarned} bits.',
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to focus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FocusFact extends StatelessWidget {
  const _FocusFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.sun.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
