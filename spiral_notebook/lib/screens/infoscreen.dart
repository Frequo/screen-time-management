import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';

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
      accent: Color(0xFFE96B2D),
      icon: Icons.phone_iphone_rounded,
    ),
    _InfoSlide(
      title: '2. Match the workload',
      body:
          'Choose an Elementary through College difficulty in Base Camp. That changes how many sparks you earn per minute.',
      accent: Color(0xFF2F8F83),
      icon: Icons.tune_rounded,
    ),
    _InfoSlide(
      title: '3. Run a focus session',
      body:
          'Start a timed focus block and leave the screen alone. Longer sessions earn better bonuses on top of the minute rate.',
      accent: Color(0xFF355C9A),
      icon: Icons.hourglass_bottom_rounded,
    ),
    _InfoSlide(
      title: '4. Pull and collect',
      body:
          'Spend sparks in the gacha banner to unlock colorful city characters. Every 200 pulls guarantees a legendary.',
      accent: Color(0xFFCF7E49),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF8E8D2), Color(0xFFE7F1EA)],
          ),
        ),
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
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      slide.accent.withValues(alpha: 0.92),
                                      slide.accent.withValues(alpha: 0.62),
                                    ],
                                  ),
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
                            const SizedBox(height: 24),
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
  });

  final String title;
  final String body;
  final Color accent;
  final IconData icon;
}
