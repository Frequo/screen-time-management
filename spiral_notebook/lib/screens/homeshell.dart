import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (BuildContext context, Widget? child) {
        final List<Widget> screens = <Widget>[
          GachaScreen(appState: widget.appState),
          InventoryScreen(
            appState: widget.appState,
            onStartFocus: () => setState(() => _selectedIndex = 2),
            onOpenGacha: () => setState(() => _selectedIndex = 0),
            onOpenCollection: () => Navigator.pushNamed(context, '/characters'),
          ),
          FocusScreen(appState: widget.appState),
        ];

        final List<String> titles = <String>['Gacha', 'Backpack', 'Focus'];

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titles[_selectedIndex]),
                Text(
                  widget.appState.playerName.isEmpty
                      ? 'Spiral Notebook'
                      : 'Welcome back, ${widget.appState.playerName}!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: _buildActions(context),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFF8F1E6),
                  Color(0xFFF4E0BE),
                  Color(0xFFE7F0EB),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: IndexedStack(index: _selectedIndex, children: screens),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              onDestinationSelected: (int value) {
                setState(() {
                  _selectedIndex = value;
                });
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

  List<Widget> _buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        tooltip: 'How it works',
        onPressed: () => Navigator.pushNamed(context, '/info'),
        icon: const Icon(Icons.slideshow_rounded),
      ),
      if (_selectedIndex != 2)
        IconButton(
          tooltip: 'Collection',
          onPressed: () => Navigator.pushNamed(context, '/characters'),
          icon: const Icon(Icons.groups_rounded),
        ),
      if (_selectedIndex == 1)
        IconButton(
          tooltip: 'Settings',
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.tune_rounded),
        ),
      const SizedBox(width: 8),
    ];
  }
}
