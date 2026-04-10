import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/widgets/rarity_backdrop.dart';

typedef CharacterTapHandler =
    void Function(BuildContext context, GameCharacter character);

class CharacterCollectionScreen extends StatelessWidget {
  const CharacterCollectionScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character View')),
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: CharacterRosterGrid(
          appState: appState,
          padding: const EdgeInsets.all(20),
          onCharacterTap: (BuildContext context, GameCharacter character) {
            Navigator.pushNamed(context, '/character', arguments: character.id);
          },
        ),
      ),
    );
  }
}

class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({
    super.key,
    required this.appState,
    required this.character,
  });

  final SpiralAppState appState;
  final GameCharacter character;

  @override
  Widget build(BuildContext context) {
    final bool owned = appState.isCollected(character);
    return Scaffold(
      appBar: AppBar(title: Text(owned ? character.name : 'Unknown character')),
      body: CharacterDetailBody(appState: appState, character: character),
    );
  }
}

class CharacterRosterGrid extends StatelessWidget {
  const CharacterRosterGrid({
    super.key,
    required this.appState,
    required this.onCharacterTap,
    this.padding = const EdgeInsets.all(20),
    this.shrinkWrap = false,
    this.physics,
  });

  final SpiralAppState appState;
  final CharacterTapHandler onCharacterTap;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        return GridView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: appState.roster.length,
          itemBuilder: (BuildContext context, int index) {
            final GameCharacter character = appState.roster[index];
            final bool owned = appState.isCollected(character);
            return _CharacterGridTile(
              character: character,
              owned: owned,
              copies: appState.copiesOwned(character),
              onTap: () => onCharacterTap(context, character),
            );
          },
        );
      },
    );
  }
}

class CharacterDetailBody extends StatelessWidget {
  const CharacterDetailBody({
    super.key,
    required this.appState,
    required this.character,
  });

  final SpiralAppState appState;
  final GameCharacter character;

  @override
  Widget build(BuildContext context) {
    final int copies = appState.copiesOwned(character);
    final bool owned = copies > 0;

    return RarityBackdrop(
      rarity: character.rarity,
      accent: character.accent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xEE17222A)
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: _CharacterArtwork(
                    character: character,
                    owned: owned,
                    size: MediaQuery.of(context).size.width * 1.00,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  owned ? character.name : 'Unknown',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  owned
                      ? character.title
                      : 'Keep focusing to reveal this character.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: character.rarity.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _DetailPill(label: 'Rarity', value: character.rarity.label),
                    _DetailPill(
                      label: 'Owned',
                      value: owned ? 'x$copies' : 'Not collected',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  owned
                      ? character.description
                      : 'This profile unlocks after the first copy joins your roster.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showCharacterDetailSheet(
  BuildContext context, {
  required SpiralAppState appState,
  required GameCharacter character,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                appState.isCollected(character)
                    ? character.name
                    : 'Unknown character',
              ),
            ),
            body: CharacterDetailBody(appState: appState, character: character),
          ),
        ),
      );
    },
  );
}

class _CharacterGridTile extends StatelessWidget {
  const _CharacterGridTile({
    required this.character,
    required this.owned,
    required this.copies,
    required this.onTap,
  });

  final GameCharacter character;
  final bool owned;
  final int copies;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: owned
              ? Theme.of(context).cardColor
              : Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B242B)
              : const Color(0xFFF0ECE4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Container(
                    height: 108,
                    width: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: owned ? character.accent : const Color(0xFFD3D0C9),
                    ),
                    child: owned
                        ? ClipOval(
                            child: Image.asset(
                              character.portraitAsset,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.lock_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              Text(
                owned ? character.name : 'Unknown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                owned ? character.title : 'Tap to preview this character.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                owned
                    ? '${character.rarity.label}  ·  x$copies'
                    : character.rarity.label,
                style: TextStyle(color: character.rarity.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterArtwork extends StatelessWidget {
  const _CharacterArtwork({
    required this.character,
    required this.owned,
    required this.size,
  });

  final GameCharacter character;
  final bool owned;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: owned ? character.accent : const Color(0xFFD3D0C9),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: character.accent.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: owned
          ? Image.asset(character.mainAsset, fit: BoxFit.cover)
          : const Icon(Icons.lock_rounded, size: 120, color: Colors.white),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E2A32)
            : const Color(0xFFF4EFE8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}
