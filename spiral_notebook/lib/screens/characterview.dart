import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';

class CharacterCollectionScreen extends StatelessWidget {
  const CharacterCollectionScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Character View')),
          body: ColoredBox(
            color: const Color(0xFFF0F4F2),
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
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
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: owned
                      ? () => Navigator.pushNamed(
                          context,
                          '/character',
                          arguments: character.id,
                        )
                      : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: owned ? Colors.white : const Color(0xFFF0ECE4),
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
                                  color: owned
                                      ? character.accent
                                      : const Color(0xFFD3D0C9),
                                ),
                                child: Icon(
                                  owned
                                      ? _rarityIcon(character.rarity)
                                      : Icons.lock_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            owned ? character.name : 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            owned
                                ? character.title
                                : 'Keep focusing to reveal this resident.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            owned
                                ? '${character.rarity.label}  ·  x${appState.copiesOwned(character)}'
                                : character.rarity.label,
                            style: TextStyle(color: character.rarity.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
    final int copies = appState.copiesOwned(character);
    return Scaffold(
      appBar: AppBar(title: Text(character.name)),
      body: ColoredBox(
        color: character.accent.withValues(alpha: 0.18),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: character.accent,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: character.accent.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Icon(
                        _rarityIcon(character.rarity),
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    character.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    character.title,
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
                      _DetailPill(
                        label: 'Rarity',
                        value: character.rarity.label,
                      ),
                      _DetailPill(label: 'Owned', value: 'x$copies'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    character.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        color: const Color(0xFFF4EFE8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

IconData _rarityIcon(CharacterRarity rarity) {
  return switch (rarity) {
    CharacterRarity.common => Icons.person,
    CharacterRarity.rare => Icons.flash_on_rounded,
    CharacterRarity.epic => Icons.local_fire_department_rounded,
    CharacterRarity.legendary => Icons.stars_rounded,
  };
}
