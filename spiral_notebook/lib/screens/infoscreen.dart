import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/widgets/difficulty_selector_card.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  final List<_InfoSlide> _slides = const <_InfoSlide>[
    _InfoSlide(
      title: '1. Park the phone',
      body:
          'Set the phone on a stand where it is visible but out of your hands. The app treats that as your focus station.',
      accent: Color(0xFF5DAFA3),
      icon: Icons.phone_iphone_rounded,
    ),
    _InfoSlide(
      title: '2. Match the workload',
      body:
          'Choose an Elementary through College difficulty here before you start. That changes how many bits you earn per minute.',
      accent: Color(0xFF6E9BB8),
      icon: Icons.tune_rounded,
      showsDifficultySelector: true,
    ),
    _InfoSlide(
      title: '3. Run a focus session',
      body:
          'Start a timed focus block and leave the screen alone. Longer sessions earn better bonuses on top of the minute rate.',
      accent: Color(0xFF4D6E9F),
      icon: Icons.hourglass_bottom_rounded,
    ),
    _InfoSlide(
      title: '4. Pull and collect',
      body:
          'Spend bits in the gacha banner to unlock colorful city characters. Every 100 pulls guarantees a legendary.',
      accent: Color(0xFF7DA3A0),
      icon: Icons.auto_awesome,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How it works')),
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int value) {
                      setState(() {
                        _index = value;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final _InfoSlide slide = _slides[index];
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              slide.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.body,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 24),
                            if (slide.showsDifficultySelector)
                              Expanded(
                                child: SingleChildScrollView(
                                  child: DifficultySelectorCard(
                                    appState: widget.appState,
                                    title: 'Pick your starting difficulty',
                                    description:
                                        'Choose how fast focus minutes turn into bits before you enter the app. You can change this again from Inventory at any time.',
                                    padding: const EdgeInsets.all(18),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    color: slide.accent,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      slide.icon,
                                      color: Colors.white,
                                      size: 84,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(_slides.length, (int index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 10,
                      width: index == _index ? 28 : 10,
                      decoration: BoxDecoration(
                        color: index == _index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _index == 0
                            ? null
                            : () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                );
                              },
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _index == _slides.length - 1
                            ? () => Navigator.pop(context)
                            : () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                );
                              },
                        child: Text(
                          _index == _slides.length - 1 ? 'Done' : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSlide {
  const _InfoSlide({
    required this.title,
    required this.body,
    required this.accent,
    required this.icon,
    this.showsDifficultySelector = false,
  });

  final String title;
  final String body;
  final Color accent;
  final IconData icon;
  final bool showsDifficultySelector;
}
