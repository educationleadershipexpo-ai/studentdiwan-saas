import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final transAsync = ref.watch(transportProvider(kid.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'Transport Tracker'),
      body: transAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load transport data', onRetry: () => ref.invalidate(transportProvider(kid.id))),
        data: (data) {
          final enrollment = data['enrollment'] as TransportEnrollment?;
          final route = data['route'] as TransportRoute?;
          final vehicle = data['vehicle'] as TransportVehicle?;

          if (enrollment == null) return const EmptyState(
            icon: Icons.directions_bus_outlined,
            title: 'Not Enrolled in Transport',
            subtitle: 'This student is not enrolled in any school transport route.',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(children: [
              // Map placeholder
              Container(
                height: 175,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE8F4E8), Color(0xFFC8E6C9)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(children: [
                  const Center(child: Icon(Icons.map_rounded, size: 56, color: Color(0xFF81C784))),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Live Tracking', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // Bus info
              WhiteCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(vehicle?.vehicleNumber ?? 'Bus', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      Text(route?.name ?? '', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                    ])),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _TransStat('Pickup', enrollment.pickupTime ?? 'N/A')),
                    Expanded(child: _TransStat('Drop-off', enrollment.dropoffTime ?? 'N/A')),
                    Expanded(child: _TransStat('Stop', enrollment.stopName ?? 'N/A')),
                  ]),
                  if (vehicle?.driverName != null) ...[
                    const Divider(height: 20, color: AppColors.primarySurface),
                    InfoRow(label: 'Driver', value: vehicle!.driverName!),
                    if (vehicle.driverContact != null) InfoRow(label: 'Contact', value: vehicle.driverContact!, isLast: true),
                  ],
                ]),
              ),

              if (route != null && route.routeNumber != null) ...[
                const SectionHeader(title: 'Route Info'),
                WhiteCard(
                  child: Column(children: [
                    InfoRow(label: 'Route Number', value: route.routeNumber!),
                    InfoRow(label: 'Route Name', value: route.name, isLast: true),
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

class _TransStat extends StatelessWidget {
  final String label, value;
  const _TransStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.text1)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.text3, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
  ]);
}
