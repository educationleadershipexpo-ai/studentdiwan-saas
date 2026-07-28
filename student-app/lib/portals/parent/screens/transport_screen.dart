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
      backgroundColor: context.bgColor,
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

              // Route Stops — real published stop list (same source as desktop).
              // The child's own stop is highlighted; empty state is honest when
              // the admin hasn't published stop details for this route yet.
              if (route != null) ...[
                const SectionHeader(title: 'Route Stops'),
                WhiteCard(
                  child: route.stopsList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No stop details published for this route yet.',
                              style: TextStyle(fontSize: 12, color: AppColors.text3),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < route.stopsList.length; i++)
                              _StopRow(
                                stop: route.stopsList[i],
                                isChildStop: _sameStop(route.stopsList[i].name, enrollment.stopName),
                                isLast: i == route.stopsList.length - 1,
                                childFirstName: kid.firstName,
                              ),
                          ],
                        ),
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

// Case/spacing-tolerant comparison of a route stop name against the child's
// enrolled stop, so the child's own stop can be highlighted on the timeline.
bool _sameStop(String? a, String? b) {
  String norm(String? s) => (s ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final na = norm(a);
  return na.isNotEmpty && na == norm(b);
}

class _StopRow extends StatelessWidget {
  final TransportStop stop;
  final bool isChildStop;
  final bool isLast;
  final String childFirstName;

  const _StopRow({
    required this.stop,
    required this.isChildStop,
    required this.isLast,
    required this.childFirstName,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isChildStop
        ? AppColors.primary
        : isLast
            ? AppColors.blue
            : AppColors.text3.withOpacity(0.4);

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Timeline rail: dot + connecting line to the next stop.
        Column(children: [
          Container(
            width: 14, height: 14,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: AppColors.text3.withOpacity(0.18))),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    stop.name.isEmpty ? 'Stop' : stop.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isChildStop ? AppColors.primary : AppColors.text1,
                    ),
                  ),
                ),
                if (isChildStop) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryExtraLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      childFirstName.isEmpty ? 'Your stop' : "$childFirstName's stop",
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                ],
              ]),
              if (stop.address != null && stop.address!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(stop.address!, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              ],
              if (stop.time != null && stop.time!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text(stop.time!, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
                ]),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
