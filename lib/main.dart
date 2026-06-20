// lib/main.dart
//
// PERUBAHAN NAVIGASI:
// 1. HomeScreen sekarang jadi root permanen untuk SEMUA role (termasuk admin/fundraiser).
// 2. Setelah login/register, user diarahkan balik ke HomeScreen ('/'),
//    BUKAN langsung ke dashboard. Dashboard dibuka manual lewat tombol di HomeScreen.
// 3. _AuthGuard yang lama (auto-redirect saat buka root) DIHAPUS.
//    Sekarang AuthGuard hanya dipakai untuk melindungi /dashboard route
//    dari akses role yang salah, tanpa mengambil alih root.
// 4. Dashboard, Profile, dan DonationHistory diakses lewat Navigator.push()
//    biasa (bukan pushReplacement), jadi tombol back selalu berfungsi.

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
import 'screens/profile/profile_screen.dart';
import 'screens/donation/donation_history_screen.dart';

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
      // HomeScreen langsung jadi initial route — tidak ada lagi
      // _RootGuard yang mengecek status auth sebelum render.
      // AuthProvider.init() berjalan di background; HomeScreen sendiri
      // yang akan reaktif menampilkan tombol Login vs Avatar profil.
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
      case '/':
        // HomeScreen SELALU jadi root — untuk guest, donor, fundraiser, admin.
        return _fade(const HomeScreen());

      case '/login':
        return _slide(const LoginScreen());

      case '/register':
        return _slide(const RegisterScreen());

      // Dashboard sekarang dibuka lewat PUSH biasa (lihat home_screen.dart),
      // bukan lagi root route yang menggantikan HomeScreen.
      // _AuthGuard tetap dipakai di sini untuk proteksi role,
      // tapi TIDAK PERNAH dipanggil sebagai initial/root route lagi.
      case '/dashboard/donor':
        return _slide(const _AuthGuard(
          role: UserRole.donatur,
          child: DonorDashboardScreen(),
        ));
      case '/dashboard/fundraiser':
        return _slide(const _AuthGuard(
          role: UserRole.fundraiser,
          child: FundraiserDashboardScreen(),
        ));
      case '/dashboard/admin':
        return _slide(const _AuthGuard(
          role: UserRole.admin,
          child: AdminDashboardScreen(),
        ));

      // ── Route baru ──────────────────────────────────
      case '/profile':
        return _slide(const _AuthGuard(child: ProfileScreen()));

      case '/donation-history':
        return _slide(const _AuthGuard(
          role: UserRole.donatur,
          child: DonationHistoryScreen(),
        ));

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
// AUTH GUARD
//
// PERUBAHAN: guard ini sekarang HANYA dipakai untuk melindungi
// route yang di-PUSH (dashboard, profile, donation-history),
// bukan lagi sebagai gatekeeper root '/'. Kalau auth gagal atau
// role salah, guard akan pop() balik ke halaman sebelumnya
// (bukan pushReplacementNamed ke halaman lain) — supaya history
// stack tetap bersih dan tombol back tetap masuk akal.
// ─────────────────────────────────────────────────────────

class _AuthGuard extends StatelessWidget {
  final Widget child;
  final UserRole? role; // null = boleh role apapun, asal sudah login
  const _AuthGuard({required this.child, this.role});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.initial) {
      return const _SplashScreen();
    }

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        Navigator.of(context).push(LoginScreen.route());
      });
      return const _SplashScreen();
    }

    if (role != null && auth.currentUser!.role != role) {
      // Role tidak cocok — pop balik daripada redirect paksa ke dashboard lain.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const _SplashScreen();
    }

    return child;
  }
}

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
