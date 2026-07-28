import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class BehaviourScreen extends ConsumerWidget {
  const BehaviourScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final behAsync = ref.watch(behaviourProvider(kid.id));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(title: 'Behaviour · ${kid.firstName}'),
      body: behAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load behaviour records', onRetry: () => ref.invalidate(behaviourProvider(kid.id))),
        data: (incidents) {
          if (incidents.isEmpty) return const EmptyState(icon: Icons.check_circle_outline_rounded, title: 'No Behaviour Incidents', subtitle: 'No discipline records on file. Keep it up!');
          final positive = incidents.where((i) {
            final t = i.type.toLowerCase();
            return t.contains('positive') || t.contains('praise') || t.contains('commend') || t.contains('award');
          }).length;
          final negative = incidents.where((i) {
            final t = i.type.toLowerCase();
            return t.contains('negative') || t.contains('incident') || t.contains('warning') ||
                   t.contains('suspension') || t.contains('detention') || t.contains('violation');
          }).length;

          return Column(children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 10)]),
              child: Row(children: [
                Expanded(child: Column(children: [
                  Text('$positive', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.green)),
                  const Text('Positive', style: TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w600)),
                ])),
                Container(width: 1, height: 40, color: AppColors.primarySurface),
                Expanded(child: Column(children: [
                  Text('$negative', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.red)),
                  const Text('Incidents', style: TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w600)),
                ])),
                Container(width: 1, height: 40, color: AppColors.primarySurface),
                Expanded(child: Column(children: [
                  Text('${incidents.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text1)),
                  const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: incidents.length,
                itemBuilder: (_, i) => _IncidentCard(incident: incidents[i]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final BehaviorIncident incident;
  const _IncidentCard({required this.incident});

  bool get isPositive => incident.type.toLowerCase().contains('positive') || incident.type.toLowerCase().contains('praise');

  @override
  Widget build(BuildContext context) => WhiteCard(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: isPositive ? AppColors.greenLight : AppColors.redLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(isPositive ? Icons.thumb_up_outlined : Icons.warning_amber_rounded,
          color: isPositive ? AppColors.green : AppColors.red, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(incident.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1))),
          if (incident.date != null) Text(DateFormat('d MMM').format(incident.date!), style: const TextStyle(fontSize: 10, color: AppColors.text3)),
        ]),
        const SizedBox(height: 3),
        Text(incident.description, style: const TextStyle(fontSize: 11, color: AppColors.text3, height: 1.4)),
        if (incident.action != null) ...[
          const SizedBox(height: 5),
          Text('Action: ${incident.action}', style: const TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600)),
        ],
      ])),
    ]),
  );
}
