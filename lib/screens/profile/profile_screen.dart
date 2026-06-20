// lib/screens/profile/profile_screen.dart
//
// FILE BARU — target dari route '/profile' dan tombol "Profil Saya"
// di menu HomeScreen.
//
// CATATAN: tidak ada endpoint PUT /api/profile di Laravel saat ini
// (instruksi eksplisit: jangan ubah API endpoints), jadi screen ini
// menampilkan data dari AuthProvider.currentUser secara read-only.
// Form edit disiapkan secara visual tapi tombol simpan dinonaktifkan
// dengan pesan jelas — supaya tidak menjanjikan fungsi yang belum ada
// backend-nya.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final tt = Theme.of(context).textTheme;

    if (user == null) {
      // Guard tambahan — seharusnya tidak pernah ke sini karena
      // route ini sudah dilindungi _AuthGuard di main.dart.
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Silakan masuk terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profil Saya'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.ink200),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + nama besar
          Center(
            child: Column(
              children: [
                UserAvatar(initial: user.initial, size: 80),
                const SizedBox(height: 16),
                Text(user.name,
                    style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: const TextStyle(
                      color: AppColors.brand700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Info akun
          Text('Informasi Akun', style: tt.headlineSmall),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.ink200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _InfoRow(icon: Icons.person_outline, label: 'Nama', value: user.name),
                const Divider(height: 1),
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                const Divider(height: 1),
                _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Peran',
                    value: user.roleLabel),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Catatan fitur edit profil
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.ink50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.ink600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fitur ubah profil akan segera tersedia.',
                    style: tt.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
