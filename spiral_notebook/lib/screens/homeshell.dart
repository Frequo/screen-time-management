import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/cutscenescreen.dart';
import 'package:spiral_notebook/screens/focusscreen.dart';
import 'package:spiral_notebook/screens/gachascreen.dart';
import 'package:spiral_notebook/screens/inventoryscreen.dart';
import 'package:spiral_notebook/screens/settingscreen.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/tutorial_overlay.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 1;
  final TutorialTargetKeys _tutorialTargets = TutorialTargetKeys();

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_syncSystemUi);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState == widget.appState) {
      return;
    }

    oldWidget.appState.removeListener(_syncSystemUi);
    widget.appState.addListener(_syncSystemUi);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_syncSystemUi);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (BuildContext context, Widget? child) {
        final bool immersiveFocus =
            (widget.appState.isFocusActive || widget.appState.isFocusPaused) &&
            _selectedIndex == 2;
        final List<Widget> screens = <Widget>[
          GachaScreen(
            appState: widget.appState,
            tutorialTargets: _tutorialTargets,
          ),
          InventoryScreen(
            appState: widget.appState,
            onStartFocus: () => setState(() => _selectedIndex = 2),
            onOpenGacha: () => setState(() => _selectedIndex = 0),
            onOpenSettings: () => _openSettings(context),
            tutorialTargets: _tutorialTargets,
          ),
          FocusScreen(
            appState: widget.appState,
            tutorialTargets: _tutorialTargets,
          ),
        ];

        final List<String> titles = <String>['Gacha', 'Inventory', 'Focus'];

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Scaffold(
              extendBody: !immersiveFocus,
              appBar: immersiveFocus
                  ? null
                  : AppBar(
                      automaticallyImplyLeading: false,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(titles[_selectedIndex]),
                          Text(
                            widget.appState.playerName.isEmpty
                                ? 'Nexi'
                                : 'Welcome back, ${widget.appState.playerName}!',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      actions: _buildActions(context),
                    ),
              body: Container(
                color: immersiveFocus
                    ? AppPalette.night
                    : Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  top: !immersiveFocus,
                  bottom: !immersiveFocus,
                  child: IndexedStack(index: _selectedIndex, children: screens),
                ),
              ),
              bottomNavigationBar: immersiveFocus
                  ? null
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: NavigationBar(
                        selectedIndex: _selectedIndex,
                        backgroundColor: Theme.of(context).cardColor,
                        onDestinationSelected: (int value) {
                          setState(() {
                            _selectedIndex = value;
                          });
                          if (widget.appState.isTutorialActive &&
                              widget.appState.tutorialStep ==
                                  TutorialStep.openFocus &&
                              value == 2) {
                            widget.appState.setTutorialStep(
                              TutorialStep.startFocus,
                            );
                          } else if (widget.appState.isTutorialActive &&
                              widget.appState.tutorialStep ==
                                  TutorialStep.openGacha &&
                              value == 0) {
                            widget.appState.setTutorialStep(
                              TutorialStep.gachaBits,
                            );
                          }
                          _syncSystemUi();
                        },
                        destinations: <NavigationDestination>[
                          NavigationDestination(
                            key: _tutorialTargets.gachaTab,
                            icon: const Icon(Icons.auto_awesome),
                            label: 'Gacha',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.home_rounded),
                            label: 'Inventory',
                          ),
                          NavigationDestination(
                            key: _tutorialTargets.focusTab,
                            icon: const Icon(Icons.hourglass_bottom),
                            label: 'Focus',
                          ),
                        ],
                      ),
                    ),
            ),
            if (_shouldShowShellTutorial)
              TutorialOverlay(
                appState: widget.appState,
                targetKeys: _tutorialTargets,
                onPrimary: () => _handleTutorialPrimary(context),
                onSkip: widget.appState.skipTutorial,
              ),
          ],
        );
      },
    );
  }

  void _syncSystemUi() {
    final bool immersive =
        (widget.appState.isFocusActive || widget.appState.isFocusPaused) &&
        _selectedIndex == 2;
    SystemChrome.setEnabledSystemUIMode(
      immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_selectedIndex == 2) {
      return const <Widget>[SizedBox(width: 8)];
    }

    return <Widget>[
      IconButton(
        key: _tutorialTargets.settingsButton,
        tooltip: 'Settings',
        onPressed: () => _openSettings(context),
        icon: const Icon(Icons.tune_rounded),
      ),
      IconButton(
        tooltip: 'How it works',
        onPressed: () => Navigator.pushNamed(context, '/info'),
        icon: const Icon(Icons.slideshow_rounded),
      ),
      const SizedBox(width: 8),
    ];
  }

  bool get _shouldShowShellTutorial {
    if (!widget.appState.isTutorialActive) {
      return false;
    }

    return switch (widget.appState.tutorialStep) {
      TutorialStep.inventoryWelcome ||
      TutorialStep.bitsBalance ||
      TutorialStep.difficultyRewards ||
      TutorialStep.collection ||
      TutorialStep.openFocus ||
      TutorialStep.startFocus ||
      TutorialStep.focusTargets ||
      TutorialStep.openGacha ||
      TutorialStep.gachaBits ||
      TutorialStep.drawOne ||
      TutorialStep.openSettings => true,
      TutorialStep.settingsDifficulty ||
      TutorialStep.settingsReactivate ||
      TutorialStep.finish => false,
    };
  }

  void _handleTutorialPrimary(BuildContext context) {
    switch (widget.appState.tutorialStep) {
      case TutorialStep.openFocus:
        setState(() {
          _selectedIndex = 2;
        });
        widget.appState.setTutorialStep(TutorialStep.startFocus);
        return;
      case TutorialStep.openGacha:
        setState(() {
          _selectedIndex = 0;
        });
        widget.appState.setTutorialStep(TutorialStep.gachaBits);
        return;
      case TutorialStep.drawOne:
        final List<GameCharacter> results = widget.appState.tutorialDrawOne();
        widget.appState.setTutorialStep(TutorialStep.openSettings);
        Navigator.pushNamed(
          context,
          '/cutscene',
          arguments: CutsceneArgs(characters: results),
        );
        return;
      case TutorialStep.openSettings:
        widget.appState.setTutorialStep(TutorialStep.settingsDifficulty);
        _openSettings(context);
        return;
      case TutorialStep.finish:
        widget.appState.completeTutorial();
        return;
      default:
        widget.appState.advanceTutorial();
    }
  }

  void _openSettings(BuildContext context) {
    if (widget.appState.isTutorialActive &&
        widget.appState.tutorialStep == TutorialStep.openSettings) {
      widget.appState.setTutorialStep(TutorialStep.settingsDifficulty);
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SettingsScreen(
            appState: widget.appState,
            tutorialTargets: _tutorialTargets,
          );
        },
      ),
    );
  }
}
