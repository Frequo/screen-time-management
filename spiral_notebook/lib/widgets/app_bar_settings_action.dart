import 'package:flutter/material.dart';

class AppBarSettingsAction extends StatelessWidget {
  const AppBarSettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      onPressed: () => Navigator.pushNamed(context, '/settings'),
      icon: const Icon(Icons.tune_rounded),
    );
  }
}
