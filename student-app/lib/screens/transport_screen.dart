import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Real transport allocation for the logged-in student, read from
// transport_enrollments → transport_routes → transport_vehicles → staff
// (studentTransportProvider). Students not enrolled in transport see a clear
// empty state instead of a fabricated bus, driver, and animated GPS map.
class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  Future<void> _call(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start the call.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(studentTransportProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'School Transport',
            subtitle: 'Your bus route, stop, and driver contact',
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: infoAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SkeletonLoader(width: double.infinity, height: 160),
              ),
              error: (err, stack) => const Center(
                child: Text('Could not load transport details right now.',
                    style: TextStyle(color: AppColors.text3)),
              ),
              data: (info) {
                if (!info.isEnrolled) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(studentTransportProvider),
                    child: ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.directions_bus_outlined, size: 64, color: AppColors.text3),
                              SizedBox(height: 12),
                              Text('You are not enrolled in school transport.',
                                  style: TextStyle(color: AppColors.text3, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('Contact the transport office to register.',
                                  style: TextStyle(color: AppColors.text3, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final alloc = info.allocation!;
                final route = info.route;
                final vehicle = info.vehicle;
                final driver = info.driver;

                final routeName = '${route?['name'] ?? alloc['route'] ?? '—'}';
                final busReg = '${vehicle?['regNumber'] ?? alloc['vehicle'] ?? '—'}';
                final stopName = '${alloc['stopName'] ?? '—'}';
                final mode = '${alloc['mode'] ?? ''}';
                final status = '${alloc['status'] ?? ''}';
                final driverName = '${driver?['name'] ?? vehicle?['driver'] ?? '—'}';
                final driverPhone = '${driver?['phone'] ?? driver?['mobile'] ?? ''}';
                final helper = '${vehicle?['helper'] ?? ''}';

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(studentTransportProvider),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Route + driver card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: AppColors.primaryExtraLight, shape: BoxShape.circle),
                                  child: const Icon(Icons.directions_bus_rounded,
                                      color: AppColors.primary, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(routeName, style: context.heading3.copyWith(fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text('Driver: $driverName',
                                          style: const TextStyle(color: AppColors.text2, fontSize: 12.5)),
                                      if (helper.isNotEmpty)
                                        Text('Helper: $helper',
                                            style: const TextStyle(color: AppColors.text3, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                if (driverPhone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded, color: AppColors.green, size: 24),
                                    onPressed: () => _call(context, driverPhone),
                                  ),
                              ],
                            ),
                            if (status.isNotEmpty || mode.isNotEmpty) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  if (mode.isNotEmpty)
                                    StatusChip(
                                      label: mode.toUpperCase(),
                                      textColor: AppColors.primary,
                                      bgColor: AppColors.primarySurface,
                                    ),
                                  const SizedBox(width: 8),
                                  if (status.isNotEmpty)
                                    StatusChip(
                                      label: status.toUpperCase(),
                                      textColor: AppColors.green,
                                      bgColor: AppColors.greenLight,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bus + stop details
                      Row(
                        children: [
                          Expanded(
                            child: _detailBox('YOUR STOP', stopName, Icons.location_on_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _detailBox('BUS NUMBER', busReg, Icons.confirmation_number_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Route stops
                      if (info.stops.isNotEmpty) ...[
                        Text('Route Stops', style: context.heading2),
                        const SizedBox(height: 12),
                        ...info.stops.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          final name = '${s['name'] ?? ''}';
                          final time = '${s['time'] ?? ''}';
                          final isMyStop = name.toLowerCase() == stopName.toLowerCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isMyStop ? AppColors.primarySurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isMyStop ? AppColors.primary : AppColors.primaryExtraLight,
                                width: isMyStop ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isMyStop ? AppColors.primary : AppColors.primaryExtraLight,
                                  child: Text('${i + 1}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isMyStop ? Colors.white : AppColors.primary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(name,
                                      style: context.heading3.copyWith(
                                          fontSize: 13.5,
                                          color: isMyStop ? AppColors.primary : AppColors.text1)),
                                ),
                                if (time.isNotEmpty)
                                  Text(time, style: context.bodySmall),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: AppColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text1)),
        ],
      ),
    );
  }
}
