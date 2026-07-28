import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(studentHealthProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Health & Medical Log',
            subtitle: 'View your health summary, allergies, and nurse visit history',
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: healthAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load health records.')),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.health_and_safety_outlined, size: 64, color: AppColors.text3),
                          const SizedBox(height: 16),
                          Text('No health record on file', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
                          const SizedBox(height: 8),
                          const Text('Contact the school nurse or admin to add your health profile.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.text3, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                final bloodGroup = data['bloodGroup'] ?? '—';
                final height = data['height'] ?? '—';
                final weight = data['weight'] ?? '—';
                final allergies = (data['allergies'] as List?)?.cast<String>() ?? [];
                final vaccinations = (data['vaccinations'] as List?) ?? [];
                final nurseVisits = (data['nurseVisits'] as List?) ?? [];

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Summary card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem('BLOOD GROUP', bloodGroup, Icons.bloodtype_rounded, AppColors.red),
                          _statItem('HEIGHT', height, Icons.height_rounded, AppColors.primary),
                          _statItem('WEIGHT', weight, Icons.monitor_weight_rounded, AppColors.purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Allergies section
                    Text('Allergies & Medical Alerts', style: context.heading2),
                    const SizedBox(height: 10),
                    if (allergies.isEmpty)
                      const Text('No known medical allergies reported.', style: TextStyle(color: AppColors.text3))
                    else
                      Wrap(
                        spacing: 8,
                        children: allergies.map((a) => Chip(
                          avatar: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                          label: Text(a, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          side: BorderSide.none,
                        )).toList(),
                      ),
                    const SizedBox(height: 24),

                    // Vaccinations
                    Text('Vaccination Records', style: context.heading2),
                    const SizedBox(height: 10),
                    ...vaccinations.map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryExtraLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Date: ${v['date'] ?? ''}', style: context.bodySmall),
                              ],
                            ),
                          ),
                          StatusChip(label: v['status'] ?? 'Completed', textColor: AppColors.green, bgColor: AppColors.greenLight),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Nurse Visits
                    Text('School Nurse Visits', style: context.heading2),
                    const SizedBox(height: 10),
                    if (nurseVisits.isEmpty)
                      const Text('No nurse visits logged.', style: TextStyle(color: AppColors.text3))
                    else
                      ...nurseVisits.map((nv) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryExtraLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nv['reason'] ?? 'Clinic visit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Action: ${nv['action'] ?? ''} · Date: ${nv['date'] ?? ''}', style: context.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
