import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/focusscreen.dart';
import 'package:spiral_notebook/screens/gachascreen.dart';
import 'package:spiral_notebook/screens/inventoryscreen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 1;

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
          GachaScreen(appState: widget.appState),
          InventoryScreen(
            appState: widget.appState,
            onStartFocus: () => setState(() => _selectedIndex = 2),
            onOpenGacha: () => setState(() => _selectedIndex = 0),
            onOpenSettings: () => Navigator.pushNamed(context, '/settings'),
          ),
          FocusScreen(appState: widget.appState),
        ];

        final List<String> titles = <String>['Gacha', 'Inventory', 'Focus'];

        return Scaffold(
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
                ? const Color(0xFF121826)
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
                      _syncSystemUi();
                    },
                    destinations: const <NavigationDestination>[
                      NavigationDestination(
                        icon: Icon(Icons.auto_awesome),
                        label: 'Gacha',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.home_rounded),
                        label: 'Inventory',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.hourglass_bottom),
                        label: 'Focus',
                      ),
                    ],
                  ),
                ),
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
    return <Widget>[
      IconButton(
        tooltip: 'How it works',
        onPressed: () => Navigator.pushNamed(context, '/info'),
        icon: const Icon(Icons.slideshow_rounded),
      ),
      const SizedBox(width: 8),
    ];
  }
}
