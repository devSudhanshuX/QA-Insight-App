import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/services/session_storage.dart';
import 'package:qa_insight_hub/core/theme/app_theme.dart';
import 'package:qa_insight_hub/features/auth/presentation/views/login_view.dart';
import 'package:qa_insight_hub/features/home/presentation/views/q_dashboard_shell.dart';

class QaInsightApp extends StatelessWidget {
  const QaInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QA Insight Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _LaunchView(),
    );
  }
}

class _LaunchView extends StatefulWidget {
  const _LaunchView();

  @override
  State<_LaunchView> createState() => _LaunchViewState();
}

class _LaunchViewState extends State<_LaunchView>
    with SingleTickerProviderStateMixin {
  final SessionStorage _sessionStorage = SessionStorage();
  late final Future<AuthSession?> _bootFuture;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bootFuture = _prepare();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  Future<AuthSession?> _prepare() async {
    final stopwatch = Stopwatch()..start();
    final session = await _sessionStorage.getSession();
    const minSplashTime = Duration(milliseconds: 2300);
    final remaining = minSplashTime - stopwatch.elapsed;
    if (!remaining.isNegative) {
      await Future.delayed(remaining);
    }
    return session;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _bootFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => _SplashScreen(
              pulse: _pulseController.value,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const LoginView();
        }
        return QDashboardShell(session: snapshot.data!);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final scale = 0.94 + (pulse * 0.08);
    final opacity = 0.65 + (pulse * 0.35);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B2D86),
              Color(0xFF1976D2),
              Color(0xFF1FC9D1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(44),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x6600175D),
                          blurRadius: 34,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/branding/qa_insight_hub_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'QA Insight Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quality, Verified.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
