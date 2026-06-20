// lib/screens/dashboard/donor_dashboard_screen.dart
//
// PERUBAHAN BESAR:
// Sebelumnya screen ini meniru HomeScreen (hero section, campaign grid,
// "Mulai Berdonasi" CTA) — sehingga peran dashboard dan homepage tumpang
// tindih, dan terasa seperti dua homepage berbeda.
//
// Sekarang dashboard donatur HANYA berisi 3 fungsi sesuai requirement:
//   1. Ringkasan donasi (total + jumlah) — bukan daftar kampanye publik
//   2. Link ke Riwayat Donasi (DonationHistoryScreen, screen terpisah)
//   3. Link ke Profil (ProfileScreen)
//
// AppBar ditambahkan tombol back eksplisit ke Home — sebelumnya hanya
// ada ikon logout, tidak ada cara kembali ke HomeScreen tanpa logout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../donation/donation_history_screen.dart';
import '../profile/profile_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});
  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationProvider>().loadMyDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth        = context.watch<AuthProvider>();
    final user         = auth.currentUser!;
    final donProvider = context.watch<DonationProvider>();
    final tt           = Theme.of(context).textTheme;

    final myDonations  = donProvider.myDonations;
    final totalDonated = myDonations.fold(0.0, (s, d) => s + d.amount);

    return Scaffold(
      // ── PERUBAHAN: AppBar dengan tombol back eksplisit ──
      // Sebelumnya tidak ada AppBar standar di sini (pakai SliverAppBar
      // custom tanpa tombol back). Sekarang back button bawaan Flutter
      // otomatis muncul karena screen ini di-push (bukan replace),
      // dan kita pastikan leading-nya jelas mengarah pop ke Home.
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
          tooltip: 'Kembali ke Beranda',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Dashboard Donatur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.ink600),
            tooltip: 'Keluar',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                // Logout dari dalam dashboard: pop balik ke Home,
                // HomeScreen otomatis re-render jadi state guest.
                Navigator.of(context).pop();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.ink200),
        ),
      ),
      body: Column(
        children: [
          Container(height: 4, color: AppColors.brand700),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand700,
              onRefresh: () => context.read<DonationProvider>().loadMyDonations(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting
                    Row(
                      children: [
                        UserAvatar(initial: user.initial, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Halo, ${user.name.split(' ').first}! 👋',
                                  style: tt.headlineSmall),
                              Text(user.email, style: tt.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ringkasan donasi — bukan daftar kampanye publik
                    Row(children: [
                      Expanded(child: StatCard(
                        label: 'Total Donasi',
                        value: fmtMoney(totalDonated),
                        icon: Icons.favorite_outline,
                        iconColor: AppColors.brand700,
                        iconBg: AppColors.brand50,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(
                        label: 'Kampanye Didukung',
                        value: '${myDonations.length}',
                        icon: Icons.campaign_outlined,
                        iconColor: const Color(0xFF1E40AF),
                        iconBg: const Color(0xFFDBEAFE),
                      )),
                    ]),
                    const SizedBox(height: 28),

                    // ── Fungsi utama dashboard donatur ──
                    Text('Menu Saya', style: tt.headlineSmall),
                    const SizedBox(height: 12),

                    _DashboardMenuTile(
                      icon: Icons.history_outlined,
                      iconBg: AppColors.brand50,
                      iconColor: AppColors.brand700,
                      title: 'Riwayat Donasi',
                      subtitle: 'Lihat semua donasi yang sudah kamu lakukan',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DonationHistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _DashboardMenuTile(
                      icon: Icons.bookmark_outline,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF1E40AF),
                      title: 'Kampanye Tersimpan',
                      subtitle: 'Kampanye yang kamu tandai untuk dilihat lagi',
                      onTap: () {
                        // Placeholder — fitur saved campaign belum ada
                        // endpoint API-nya, jadi UI disiapkan tapi
                        // belum difungsikan penuh (sesuai instruksi:
                        // tidak menambah endpoint Laravel baru).
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fitur ini akan segera hadir')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _DashboardMenuTile(
                      icon: Icons.person_outline,
                      iconBg: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF065F46),
                      title: 'Pengaturan Profil',
                      subtitle: 'Kelola data diri dan preferensi akun',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU TILE — reusable, dipakai juga di fundraiser/admin dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardMenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: tt.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink500),
          ],
        ),
      ),
    );
  }
}
