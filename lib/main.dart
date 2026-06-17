// lib/main.dart
// REST version — tidak ada Firebase

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/donation_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/campaign_service.dart';
import 'services/donation_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/donor_dashboard_screen.dart';
import 'screens/dashboard/fundraiser_dashboard_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Dependency injection ──────────────────────────
  final prefs        = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(prefs);
  final apiClient    = ApiClient(tokenStorage);

  final authService     = AuthService(apiClient, tokenStorage);
  final campaignService = CampaignService(apiClient);
  final donationService = DonationService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => CampaignProvider(campaignService),
        ),
        ChangeNotifierProvider(
          create: (_) => DonationProvider(donationService),
        ),
      ],
      child: const DonateIDApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// ROOT APP
// ─────────────────────────────────────────────────────────

class DonateIDApp extends StatelessWidget {
  const DonateIDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonateID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

// ─────────────────────────────────────────────────────────
// ROUTER
// ─────────────────────────────────────────────────────────

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':          return _fade(const _RootGuard());
      case '/login':     return _slide(const LoginScreen());
      case '/register':  return _slide(const RegisterScreen());
      case '/donor':
        return _fade(const _AuthGuard(role: UserRole.donatur,
            child: DonorDashboardScreen()));
      case '/fundraiser':
        return _fade(const _AuthGuard(role: UserRole.fundraiser,
            child: FundraiserDashboardScreen()));
      case '/admin':
        return _fade(const _AuthGuard(role: UserRole.admin,
            child: AdminDashboardScreen()));
      default:
        return _fade(const HomeScreen());
    }
  }

  static PageRoute _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 250),
  );

  static PageRoute _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(
          begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: FadeTransition(opacity: anim, child: child),
    ),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

// ─────────────────────────────────────────────────────────
// ROOT GUARD
// ─────────────────────────────────────────────────────────

class _RootGuard extends StatefulWidget {
  const _RootGuard();
  @override
  State<_RootGuard> createState() => _RootGuardState();
}

class _RootGuardState extends State<_RootGuard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.of(context)
          .pushReplacementNamed(_dashboardRoute(auth));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.initial) return const _SplashScreen();
    return const HomeScreen();
  }
}

// ─────────────────────────────────────────────────────────
// AUTH GUARD
// ─────────────────────────────────────────────────────────

class _AuthGuard extends StatelessWidget {
  final Widget child;
  final UserRole role;
  const _AuthGuard({required this.child, required this.role});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.initial) return const _SplashScreen();

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          Navigator.of(context).pushReplacementNamed('/login'));
      return const _SplashScreen();
    }

    if (auth.currentUser!.role != role) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          Navigator.of(context)
              .pushReplacementNamed(_dashboardRoute(auth)));
      return const _SplashScreen();
    }

    return child;
  }
}

String _dashboardRoute(AuthProvider auth) =>
    auth.isAdmin ? '/admin' : auth.isFundraiser ? '/fundraiser' : '/donor';

// ─────────────────────────────────────────────────────────
// SPLASH
// ─────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.brand700,
              child: Icon(Icons.volunteer_activism,
                  color: Colors.white, size: 32),
            ),
            SizedBox(height: 16),
            Text('DonateID',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.ink900, letterSpacing: -0.5,
                )),
            SizedBox(height: 32),
            CircularProgressIndicator(
                color: AppColors.brand700, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
