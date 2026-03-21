import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/onboarding.mp4',
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController!.setLooping(false);
        _videoController!.pause();
      });

    _pageController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final page = _pageController.page ?? 0.0;

    // Detect if user is actively scrolling
    final isScrolling = (page - page.round()).abs() > 0.01;

    if (isScrolling) {
      // Play video while scrolling
      if (!_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    } else {
      // Snap to keyframes when settled
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      }

      final duration = _videoController!.value.duration;

      double targetProgress;

      if (page.round() == 0) {
        targetProgress = 0.0;
      } else if (page.round() == 1) {
        targetProgress = 0.5;
      } else {
        targetProgress = 0.99;
      }

      final targetPosition = Duration(
        milliseconds: (duration.inMilliseconds * targetProgress).toInt(),
      );

      _videoController!.seekTo(targetPosition);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _videoController != null && _videoController!.value.isInitialized
              ? SizedBox.expand(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          PageView(
            controller: _pageController,
            children: [
              _OnboardingPage(
                index: 0,
                controller: _pageController,
                title: "Connect Helmet",
                subtitle: "Pair your smart helmet instantly",
              ),
              _OnboardingPage(
                index: 1,
                controller: _pageController,
                title: "Control Audio",
                subtitle: "Manage calls and music seamlessly",
              ),
              _OnboardingPage(
                index: 2,
                controller: _pageController,
                title: "Stay Safe",
                subtitle: "Get alerts and ride smarter",
              ),
            ],
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: const WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final int index;
  final PageController controller;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double page = 0.0;

        if (controller.hasClients && controller.page != null) {
          page = controller.page!;
        }

        // Distance from current page
        double diff = (page - index).abs();

        // Opacity decreases as we move away
        double opacity = (1 - diff).clamp(0.0, 1.0);

        // Slight upward slide effect
        double translateY = 50 * diff;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}