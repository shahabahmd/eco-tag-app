import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';

// ─── design tokens ────────────────────────────────────────────────────────────
const _kG1 = Color(0xFF4DBB87);
const _kG2 = Color(0xFF7ED6A7);
final _kGrad = const LinearGradient(
    colors: [_kG1, _kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Check auth FIRST — synchronous, no frame budget used
  final bool _isLoggedIn =
      FirebaseAuth.instance.currentUser != null;

  // Phase 1: entrance — logo fades + scales in
  late final AnimationController _enterCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
  late final Animation<double> _enterFade =
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  late final Animation<double> _enterScale =
      Tween<double>(begin: 0.65, end: 1.0).animate(
          CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut));

  // Phase 2: exit — logo slides up, bg fades out
  late final AnimationController _exitCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _logoSlide =
      Tween<double>(begin: 0.0, end: -1.6).animate(
          CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInQuart));
  late final Animation<double> _bgFade =
      Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

  // Dots: separate, independent repeat controller
  late final AnimationController _dotsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Entrance
    await _enterCtrl.forward();
    // Hold
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    // Exit
    _dotsCtrl.stop();
    await _exitCtrl.forward();
    if (!mounted) return;
    // Navigate with smooth slide-up
    Navigator.pushReplacement(
      context,
      _SlideUpRoute(
        child: _isLoggedIn ? const HomePage() : const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _exitCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background — fades out independently ───────────────────────
            AnimatedBuilder(
              animation: _bgFade,
              builder: (_, __) => Opacity(
                opacity: _bgFade.value,
                child: Container(decoration: BoxDecoration(gradient: _kGrad)),
              ),
            ),

            // ── Logo block — slides up independently ───────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_enterCtrl, _exitCtrl]),
              builder: (_, child) {
                final slideOffset =
                    Offset(0, _logoSlide.value);
                return FractionalTranslation(
                  translation: slideOffset,
                  child: FadeTransition(
                    opacity: _enterFade,
                    child: ScaleTransition(
                      scale: _enterScale,
                      child: child,
                    ),
                  ),
                );
              },
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Logo circle
                  RepaintBoundary(
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2.5),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 28, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 58),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Eco-Tag',
                      style: TextStyle(color: Colors.white, fontSize: 36,
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Protect nature together',
                      style: TextStyle(color: Colors.white70, fontSize: 14,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 40),

                  // Dots — isolated in own RepaintBoundary
                  RepaintBoundary(child: _Dots(controller: _dotsCtrl)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing dots ─────────────────────────────────────────────────────────────
class _Dots extends AnimatedWidget {
  const _Dots({required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (t * 3 - i).clamp(0.0, 1.0);
        final opacity = math.sin(phase * math.pi).abs().clamp(0.2, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity: opacity,
            child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Colors.white70, shape: BoxShape.circle)),
          ),
        );
      }),
    );
  }
}

// ─── Custom route: destination slides up smoothly ─────────────────────────────
class _SlideUpRoute extends PageRouteBuilder {
  final Widget child;
  _SlideUpRoute({required this.child})
      : super(
          pageBuilder: (_, __, ___) => child,
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, anim, __, page) {
            return SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: anim, curve: Curves.easeOut),
                child: page,
              ),
            );
          },
        );
}
