import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

class TutorialTargetKeys {
  final GlobalKey inventoryHero = GlobalKey(
    debugLabel: 'tutorialInventoryHero',
  );
  final GlobalKey bits = GlobalKey(debugLabel: 'tutorialBits');
  final GlobalKey difficulty = GlobalKey(debugLabel: 'tutorialDifficulty');
  final GlobalKey collection = GlobalKey(debugLabel: 'tutorialCollection');
  final GlobalKey focusTab = GlobalKey(debugLabel: 'tutorialFocusTab');
  final GlobalKey focusStart = GlobalKey(debugLabel: 'tutorialFocusStart');
  final GlobalKey focusTargets = GlobalKey(debugLabel: 'tutorialFocusTargets');
  final GlobalKey gachaTab = GlobalKey(debugLabel: 'tutorialGachaTab');
  final GlobalKey gachaBits = GlobalKey(debugLabel: 'tutorialGachaBits');
  final GlobalKey drawOne = GlobalKey(debugLabel: 'tutorialDrawOne');
  final GlobalKey settingsButton = GlobalKey(
    debugLabel: 'tutorialSettingsButton',
  );
  final GlobalKey settingsDifficulty = GlobalKey(
    debugLabel: 'tutorialSettingsDifficulty',
  );
  final GlobalKey settingsReactivate = GlobalKey(
    debugLabel: 'tutorialSettingsReactivate',
  );
}

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.appState,
    required this.targetKeys,
    required this.onPrimary,
    required this.onSkip,
  });

  final SpiralAppState appState;
  final TutorialTargetKeys targetKeys;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect();
    });
  }

  @override
  void didUpdateWidget(covariant TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState.tutorialStep != widget.appState.tutorialStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTargetRect();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TutorialCopy copy = _copyFor(widget.appState.tutorialStep);
    final Rect screenRect = Offset.zero & MediaQuery.sizeOf(context);
    final Rect targetRect = _targetRect ?? _fallbackRect(screenRect);

    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TutorialSpotlightPainter(targetRect: targetRect),
              ),
            ),
          ),
          _SpotlightBorder(rect: targetRect),
          _GuideCard(
            copy: copy,
            targetRect: targetRect,
            onPrimary: widget.onPrimary,
            onSkip: widget.onSkip,
          ),
        ],
      ),
    );
  }

  Future<void> _updateTargetRect() async {
    if (!mounted) {
      return;
    }

    final GlobalKey? key = _keyFor(widget.appState.tutorialStep);
    final BuildContext? targetContext = key?.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    }

    if (!mounted) {
      return;
    }

    final RenderObject? renderObject = targetContext?.findRenderObject();
    final RenderBox? box = renderObject is RenderBox && renderObject.hasSize
        ? renderObject
        : null;

    if (box == null) {
      setState(() {
        _targetRect = null;
      });
      return;
    }

    final Offset offset = box.localToGlobal(Offset.zero);
    setState(() {
      _targetRect = _spotlightRectFor(
        widget.appState.tutorialStep,
        offset & box.size,
      );
    });
  }

  GlobalKey? _keyFor(TutorialStep step) {
    return switch (step) {
      TutorialStep.inventoryWelcome => widget.targetKeys.inventoryHero,
      TutorialStep.bitsBalance => widget.targetKeys.bits,
      TutorialStep.difficultyRewards => widget.targetKeys.difficulty,
      TutorialStep.collection => widget.targetKeys.collection,
      TutorialStep.openFocus => widget.targetKeys.focusTab,
      TutorialStep.startFocus => widget.targetKeys.focusStart,
      TutorialStep.focusTargets => widget.targetKeys.focusTargets,
      TutorialStep.openGacha => widget.targetKeys.gachaTab,
      TutorialStep.gachaBits => widget.targetKeys.gachaBits,
      TutorialStep.drawOne => widget.targetKeys.drawOne,
      TutorialStep.openSettings => widget.targetKeys.settingsButton,
      TutorialStep.settingsDifficulty => widget.targetKeys.settingsDifficulty,
      TutorialStep.settingsReactivate => widget.targetKeys.settingsReactivate,
      TutorialStep.finish => null,
    };
  }
}

Rect _spotlightRectFor(TutorialStep step, Rect rect) {
  final Rect sizedRect = switch (step) {
    TutorialStep.settingsDifficulty => Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height.clamp(220, 360).toDouble(),
    ),
    TutorialStep.settingsReactivate => rect,
    _ => rect,
  };

  return sizedRect.inflate(_spotlightPaddingFor(step));
}

double _spotlightPaddingFor(TutorialStep step) {
  return switch (step) {
    TutorialStep.settingsReactivate ||
    TutorialStep.drawOne ||
    TutorialStep.openSettings ||
    TutorialStep.openFocus ||
    TutorialStep.openGacha => 4,
    _ => 8,
  };
}

class TutorialCopy {
  const TutorialCopy({
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final String title;
  final String body;
  final String actionLabel;
}

TutorialCopy _copyFor(TutorialStep step) {
  return switch (step) {
    TutorialStep.inventoryWelcome => const TutorialCopy(
      title: 'Inventory',
      body:
          'This is your home base. It shows your progress, bits, collected characters, and quick paths into focus or gacha.',
      actionLabel: 'Next',
    ),
    TutorialStep.bitsBalance => const TutorialCopy(
      title: 'Check your bits',
      body:
          'The Bits stat shows your current currency. Bits are earned from completed study sessions and spent on gacha draws.',
      actionLabel: 'Next',
    ),
    TutorialStep.difficultyRewards => const TutorialCopy(
      title: 'Difficulty and rewards',
      body:
          'Change difficulty here. Each tier changes how many bits you earn per focused minute, so pick the workload that matches your study goal.',
      actionLabel: 'Next',
    ),
    TutorialStep.collection => const TutorialCopy(
      title: 'Collected characters',
      body:
          'Your character roster is here. Tap a character card to inspect its details, rarity, and owned copies.',
      actionLabel: 'Next',
    ),
    TutorialStep.openFocus => const TutorialCopy(
      title: 'Open Focus',
      body:
          'Use the Focus tab when you are ready to start a study session and earn bits.',
      actionLabel: 'Go to Focus',
    ),
    TutorialStep.startFocus => const TutorialCopy(
      title: 'Enter a study session',
      body:
          'Press Start focus session to begin the timer. During real sessions, put the phone down and finish to collect earned bits.',
      actionLabel: 'Next',
    ),
    TutorialStep.focusTargets => const TutorialCopy(
      title: 'Session length',
      body:
          'These buttons change the session target. The reward preview updates from your target length and current difficulty.',
      actionLabel: 'Next',
    ),
    TutorialStep.openGacha => const TutorialCopy(
      title: 'Open Gacha',
      body:
          'Go to the gacha banner when you want to spend bits on new characters.',
      actionLabel: 'Go to Gacha',
    ),
    TutorialStep.gachaBits => const TutorialCopy(
      title: 'Spend bits here',
      body:
          'This banner shows your bits, the pull cost, and collection progress before you draw.',
      actionLabel: 'Next',
    ),
    TutorialStep.drawOne => const TutorialCopy(
      title: 'Draw one',
      body:
          'Draw 1 spends 100 bits for one character pull. This tutorial will cover the practice pull if you do not have enough yet.',
      actionLabel: 'Draw 1',
    ),
    TutorialStep.openSettings => const TutorialCopy(
      title: 'Open Settings',
      body:
          'Settings contains account, appearance, audio, difficulty, and tutorial controls.',
      actionLabel: 'Open Settings',
    ),
    TutorialStep.settingsDifficulty => const TutorialCopy(
      title: 'Difficulty also lives here',
      body:
          'You can change difficulty and reward amount from settings too. The active tier decides the bits earned per minute.',
      actionLabel: 'Next',
    ),
    TutorialStep.settingsReactivate => const TutorialCopy(
      title: 'Reactivate tutorial',
      body:
          'Debug builds include this button so you can run onboarding again while testing.',
      actionLabel: 'Next',
    ),
    TutorialStep.finish => const TutorialCopy(
      title: 'Tutorial complete',
      body:
          'You finished onboarding. Here are 100 bonus bits. The tutorial will stay off unless reactivated from debug settings.',
      actionLabel: 'Collect 100 bits',
    ),
  };
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.copy,
    required this.targetRect,
    required this.onPrimary,
    required this.onSkip,
  });

  final TutorialCopy copy;
  final Rect targetRect;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width >= 520 ? 420 : size.width - 32;
    final bool placeAbove = targetRect.center.dy > size.height * 0.56;
    final double top = placeAbove
        ? (targetRect.top - 220).clamp(16, size.height - 236).toDouble()
        : (targetRect.bottom + 18).clamp(16, size.height - 236).toDouble();
    final double left = (targetRect.center.dx - width / 2)
        .clamp(16, size.width - width - 16)
        .toDouble();

    return Positioned(
      top: top,
      left: left,
      width: width,
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                copy.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(copy.body, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  TextButton(onPressed: onSkip, child: const Text('Skip')),
                  const Spacer(),
                  FilledButton(
                    onPressed: onPrimary,
                    child: Text(copy.actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightBorder extends StatelessWidget {
  const _SpotlightBorder({required this.rect});

  final Rect rect;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppPalette.sun, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppPalette.sun.withValues(alpha: 0.45),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  const _TutorialSpotlightPainter({required this.targetRect});

  final Rect targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final Path fullScreen = Path()..addRect(Offset.zero & size);
    final Path cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(26)),
      );
    final Path overlay = Path.combine(
      PathOperation.difference,
      fullScreen,
      cutout,
    );

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

Rect _fallbackRect(Rect screenRect) {
  final double width = (screenRect.width - 48).clamp(240, 420).toDouble();
  return Rect.fromLTWH(
    (screenRect.width - width) / 2,
    screenRect.height * 0.32,
    width,
    120,
  );
}
