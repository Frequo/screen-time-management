import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/characterview.dart';
import 'package:spiral_notebook/screens/cutscenescreen.dart';
import 'package:spiral_notebook/screens/homeshell.dart';
import 'package:spiral_notebook/screens/infoscreen.dart';
import 'package:spiral_notebook/screens/loginscreen.dart';
import 'package:spiral_notebook/screens/settingscreen.dart';

Route<dynamic> onGenerateAppRoute(
  RouteSettings settings,
  SpiralAppState appState,
) {
  switch (settings.name) {
    case '/':
      return _buildRoute(
        appState.isLoggedIn
            ? HomeShell(appState: appState)
            : LoginScreen(appState: appState),
      );
    case '/login':
      return _buildRoute(LoginScreen(appState: appState));
    case '/app':
      return _buildRoute(HomeShell(appState: appState));
    case '/settings':
      return _buildRoute(SettingsScreen(appState: appState));
    case '/info':
      return _buildRoute(InfoScreen(appState: appState));
    case '/characters':
      return _buildRoute(CharacterCollectionScreen(appState: appState));
    case '/character':
      final String? characterId = settings.arguments as String?;
      final GameCharacter? character = characterId == null
          ? null
          : appState.findCharacterById(characterId);
      if (character == null) {
        return _buildRoute(
          const _MissingRouteScreen(message: 'Character not found'),
        );
      }
      return _buildRoute(
        CharacterDetailScreen(appState: appState, character: character),
      );
    case '/cutscene':
      return _buildRoute(CutsceneScreen(appState: appState));
    case '/pull-results':
      return _buildRoute(PullResultsScreen(appState: appState));
    default:
      return _buildRoute(const _MissingRouteScreen(message: 'Page not found'));
  }
}

MaterialPageRoute<void> _buildRoute(Widget child) {
  return MaterialPageRoute<void>(builder: (BuildContext context) => child);
}

class _MissingRouteScreen extends StatelessWidget {
  const _MissingRouteScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
