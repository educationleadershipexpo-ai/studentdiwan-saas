import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

List<Widget> _buildHealthRows(HealthRecord h) {
  final rows = <({String label, String value})>[];
  if (h.bloodGroup != null) rows.add((label: 'Blood Group', value: h.bloodGroup!));
  if (h.height != null)     rows.add((label: 'Height',      value: '${h.height} cm'));
  if (h.weight != null)     rows.add((label: 'Weight',      value: '${h.weight} kg'));
  if (h.lastCheckup != null) rows.add((label: 'Last Checkup', value: DateFormat('d MMM yyyy').format(h.lastCheckup!)));
  return rows.asMap().entries.map((e) =>
    InfoRow(label: e.value.label, value: e.value.value, isLast: e.key == rows.length - 1)
  ).toList();
}

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final healthAsync = ref.watch(healthProvider(kid.id));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Health · ${kid.firstName}'),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load health records', onRetry: () => ref.invalidate(healthProvider(kid.id))),
        data: (records) {
          if (records.isEmpty) return const EmptyState(icon: Icons.favorite_outline_rounded, title: 'No Health Records', subtitle: 'Health records will appear here once added by the school.');
          final h = records.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              // Vitals
              const SectionHeader(title: 'Basic Info'),
              WhiteCard(
                child: Column(children: [
                  // Build a list of present rows and mark only the last one isLast.
                  ..._buildHealthRows(h),
                ]),
              ),

              if (h.allergies != null && h.allergies!.isNotEmpty) ...[
                const SectionHeader(title: 'Allergies'),
                WhiteCard(
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(h.allergies!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1))),
                  ]),
                ),
              ],

              if (h.medicalConditions != null && h.medicalConditions!.isNotEmpty) ...[
                const SectionHeader(title: 'Medical Conditions'),
                WhiteCard(
                  child: Text(h.medicalConditions!, style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.5)),
                ),
              ],

              if (h.emergencyContact != null && h.emergencyContact!.isNotEmpty) ...[
                const SectionHeader(title: 'Emergency Contact'),
                WhiteCard(
                  child: Row(children: [
                    const Icon(Icons.local_hospital_rounded, color: AppColors.red, size: 20),
                    const SizedBox(width: 10),
                    Text(h.emergencyContact!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                  ]),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}
