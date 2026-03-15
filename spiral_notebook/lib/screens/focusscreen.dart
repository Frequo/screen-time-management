import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        final bool active = appState.isFocusActive;
        final int preview = active
            ? appState.calculateRewardForSeconds(appState.currentSessionSeconds)
            : appState.currentRewardPreview;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF10243F),
                    Color(0xFF0F9D8A),
                    Color(0xFFF1A23D),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    active ? 'Stand mode active' : 'Put the phone down',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    active
                        ? 'Leave the device on its stand and let the timer run.'
                        : 'Start a session, step away from the screen, and convert quiet time into sparks.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            Icons.hourglass_bottom_rounded,
                            color: Colors.white,
                            size: 94,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          appState.formatDuration(
                            active
                                ? appState.currentSessionSeconds
                                : appState.selectedFocusTarget * 60,
                          ),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          active
                              ? '${appState.remainingTargetSeconds ~/ 60} min to target'
                              : '${appState.selectedFocusTarget} minute target',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: appState.selectedFocusTarget == 0
                          ? 0
                          : (appState.currentSessionSeconds /
                                    (appState.selectedFocusTarget * 60))
                                .clamp(0, 1),
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: active
                              ? () => _finishSession(context)
                              : appState.startFocusSession,
                          icon: Icon(
                            active
                                ? Icons.check_circle_outline
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            active
                                ? 'Finish and collect'
                                : 'Start focus session',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (active) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: appState.cancelFocusSession,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel session'),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                              onSelected: active
                                  ? null
                                  : (_) => appState.setFocusTarget(target),
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
                          value: '$preview sparks',
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
                        '${appState.lastFocusResult!.wholeMinutes} minutes completed for ${appState.lastFocusResult!.rewardsEarned} sparks.',
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

  void _finishSession(BuildContext context) {
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
                  'You stayed focused for ${result.wholeMinutes} minutes and earned ${result.rewardsEarned} sparks.',
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
        color: const Color(0xFFF5F3ED),
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
