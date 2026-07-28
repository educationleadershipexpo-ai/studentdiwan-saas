import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final achAsync = ref.watch(achievementsProvider(kid.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBackHeader(title: 'Achievements · ${kid.firstName}'),
      body: achAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load achievements', onRetry: () => ref.invalidate(achievementsProvider(kid.id))),
        data: (achievements) {
          if (achievements.isEmpty) return const EmptyState(icon: Icons.emoji_events_outlined, title: 'No Achievements Yet', subtitle: 'Awards and achievements will appear here.');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: achievements.length,
            itemBuilder: (_, i) => _AchCard(achievement: achievements[i]),
          );
        },
      ),
    );
  }
}

class _AchCard extends StatelessWidget {
  final AchievementModel achievement;
  const _AchCard({required this.achievement});

  Color get _levelColor {
    switch (achievement.level.toLowerCase()) {
      case 'national': return AppColors.red;
      case 'state': return AppColors.amber;
      default: return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) => WhiteCard(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 26),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(achievement.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
        const SizedBox(height: 3),
        Text(achievement.description, style: const TextStyle(fontSize: 11, color: AppColors.text3, height: 1.4)),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: _levelColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
            child: Text(achievement.level, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _levelColor)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(5)),
            child: Text(achievement.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          if (achievement.date != null) ...[
            const Spacer(),
            Text(DateFormat('d MMM yyyy').format(achievement.date!), style: const TextStyle(fontSize: 10, color: AppColors.text3)),
          ],
        ]),
      ])),
    ]),
  );
}
