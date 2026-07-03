import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/characterview.dart';
import 'package:spiral_notebook/screens/connectscreen.dart';
import 'package:spiral_notebook/screens/cutscenescreen.dart';
import 'package:spiral_notebook/screens/homeshell.dart';
import 'package:spiral_notebook/screens/infoscreen.dart';
import 'package:spiral_notebook/screens/loginscreen.dart';
import 'package:spiral_notebook/screens/settingscreen.dart';
import 'package:spiral_notebook/services/phone_stand_ble.dart';

Route<dynamic> onGenerateAppRoute(
  RouteSettings settings,
  SpiralAppState appState, {
  PhoneStandBleController? phoneStandController,
}) {
  switch (settings.name) {
    case '/':
      return _buildRoute(
        appState.isLoggedIn
            ? HomeShell(appState: appState)
            : LoginScreen(appState: appState),
        settings: settings,
      );
    case '/login':
      return _buildRoute(LoginScreen(appState: appState), settings: settings);
    case '/app':
      return _buildRoute(HomeShell(appState: appState), settings: settings);
    case '/settings':
      return _buildRoute(
        SettingsScreen(appState: appState),
        settings: settings,
      );
    case '/connect':
      return _buildRoute(
        ConnectStandScreen(
          appState: appState,
          phoneStandController: phoneStandController,
        ),
        settings: settings,
      );
    case '/info':
      return _buildRoute(InfoScreen(appState: appState), settings: settings);
    case '/characters':
      return _buildRoute(
        CharacterCollectionScreen(appState: appState),
        settings: settings,
      );
    case '/character':
      final String? characterId = settings.arguments as String?;
      final GameCharacter? character = characterId == null
          ? null
          : appState.findCharacterById(characterId);
      if (character == null) {
        return _buildRoute(
          const _MissingRouteScreen(message: 'Character not found'),
          settings: settings,
        );
      }
      return _buildRoute(
        CharacterDetailScreen(appState: appState, character: character),
        settings: settings,
      );
    case '/cutscene':
      return _buildRoute(
        CutsceneScreen(appState: appState),
        settings: settings,
      );
    case '/pull-results':
      return _buildRoute(
        PullResultsScreen(appState: appState),
        settings: settings,
      );
    default:
      return _buildRoute(
        const _MissingRouteScreen(message: 'Page not found'),
        settings: settings,
      );
  }
}

MaterialPageRoute<void> _buildRoute(Widget child, {RouteSettings? settings}) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (BuildContext context) => child,
  );
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
