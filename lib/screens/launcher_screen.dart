import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _taglineController;
  late AnimationController _bounceOutController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _subtitleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _bounceOutAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Title animations
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Subtitle animations
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Tagline animations
    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bounce out animation
    _bounceOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Title animations
    _titleSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));

    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    ));

    // Subtitle animations
    _subtitleSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOutCubic,
    ));

    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    ));

    // Tagline fade
    _taglineFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    ));

    // Bounce out animation
    _bounceOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _bounceOutController,
      curve: Curves.easeInBack,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Load environment variables in background
    await dotenv.load(fileName: ".env");

    // Remove native splash after 0.2 seconds
    Future.delayed(const Duration(milliseconds: 200), () {
      FlutterNativeSplash.remove();
    });

    // Stagger the animations for a polished entrance
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _taglineController.forward();

    // Wait before exit animation
    await Future.delayed(const Duration(milliseconds: 1500));

    // Start bounce-out animation
    _bounceOutController.forward();

    // Wait for bounce-out to complete then navigate
    await Future.delayed(const Duration(milliseconds: 500));
    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _taglineController.dispose();
    _bounceOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade600,
              Colors.indigo.shade800,
              Colors.indigo.shade900,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _bounceOutAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 1 - (_bounceOutAnimation.value * 0.3),
                      child: Transform.scale(
                        scale: 1 - (_bounceOutAnimation.value * 0.15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with glow effect
                            AnimatedBuilder(
                              animation: _logoController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Opacity(
                                    opacity: _logoFadeAnimation.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Pulsing glow effect
                                        Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                blurRadius: 30,
                                                spreadRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Logo container
                                        Container(
                                          width: 130,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 30,
                                                spreadRadius: 5,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/si_icon.png',
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 48),

                            // Title with slide and fade animation
                            AnimatedBuilder(
                              animation: _titleController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _titleSlideAnimation.value),
                                  child: Opacity(
                                    opacity: _titleFadeAnimation.value,
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withValues(alpha: 0.95),
                                        ],
                                      ).createShader(bounds),
                                      child: const Text(
                                        'SEND-IT',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 8.0,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // Subtitle with slide and fade animation
                            AnimatedBuilder(
                              animation: _subtitleController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _subtitleSlideAnimation.value),
                                  child: Opacity(
                                    opacity: _subtitleFadeAnimation.value,
                                    child: Text(
                                      'R E P L A Y S',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        letterSpacing: 6.0,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // Divider line
                            AnimatedBuilder(
                              animation: _subtitleController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _subtitleFadeAnimation.value,
                                  child: Container(
                                    width: 60,
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.6),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Tagline with fade animation
                            AnimatedBuilder(
                              animation: _taglineController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _taglineFadeAnimation.value * 0.75,
                                  child: Text(
                                    'Watch • Download • Share',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 80),

                            // Loading indicator
                            AnimatedBuilder(
                              animation: _taglineController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _taglineFadeAnimation.value * 0.6,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Loading nearby clubs',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}