import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(studentAchievementsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Achievements & Badges',
            subtitle: 'Your approved awards and academic recognitions',
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: achievementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load achievements.')),
              data: (achievements) {
                if (achievements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.text3),
                          const SizedBox(height: 16),
                          Text(
                            'No achievements yet',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Complete assignments, participate in school activities, and maintain attendance to earn your first recognition.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.text3, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(studentAchievementsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final a = achievements[index];
                      return _AchievementCard(achievement: a);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  const _AchievementCard({required this.achievement});

  Color _awardColor(String award) {
    switch (award.toLowerCase()) {
      case 'winner':
      case 'gold': return const Color(0xFFD97706);
      case 'runner-up':
      case 'silver': return const Color(0xFF6B7280);
      case 'bronze': return const Color(0xFF92400E);
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'sports': return Icons.sports_soccer_rounded;
      case 'arts': return Icons.palette_rounded;
      case 'leadership': return Icons.star_rounded;
      case 'olympiad': return Icons.science_rounded;
      case 'attendance': return Icons.check_circle_rounded;
      case 'cultural': return Icons.theater_comedy_rounded;
      case 'community': return Icons.people_rounded;
      case 'innovation': return Icons.lightbulb_rounded;
      default: return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${achievement['title'] ?? achievement['event'] ?? 'Achievement'}';
    final type = '${achievement['type'] ?? 'Custom'}';
    final award = '${achievement['award'] ?? 'Participation'}';
    final date = '${achievement['date'] ?? ''}';
    final color = _awardColor(award);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon(type), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.t1)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(label: type, color: AppColors.primary),
                    const SizedBox(width: 6),
                    _Chip(label: award, color: color),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(fontSize: 11, color: context.t3)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
