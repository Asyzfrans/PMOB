// lib/screens/donation/donation_history_screen.dart
//
// FILE BARU — sesuai requirement, riwayat donasi harus jadi screen
// terpisah, bukan ditempel di dalam DonorDashboardScreen.
//
// Reuse widget yang sudah ada: DonationTile, EmptyState, LoadingOverlay
// dari app_widgets.dart — tidak ada widget baru yang didesain dari nol.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/donation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationProvider>().loadMyDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DonationProvider>();
    final donations = provider.myDonations;
    final total = donations.fold(0.0, (s, d) => s + d.amount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Riwayat Donasi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.ink200),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand700,
        onRefresh: () => context.read<DonationProvider>().loadMyDonations(),
        child: provider.loading && donations.isEmpty
            ? const LoadingOverlay()
            : donations.isEmpty
                ? const EmptyState(
                    icon: Icons.history_outlined,
                    title: 'Belum ada donasi',
                    subtitle: 'Riwayat donasimu akan muncul di sini',
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Ringkasan total di atas
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.brand800, AppColors.brand600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Donasi',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(fmtMoney(total),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      )),
                                  const SizedBox(height: 2),
                                  Text('${donations.length} transaksi',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.receipt_long,
                                color: Colors.white24, size: 48),
                          ],
                        ),
                      ),

                      // Daftar transaksi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.ink200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: donations
                                  .map((d) => DonationTile(donation: d))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }
}
