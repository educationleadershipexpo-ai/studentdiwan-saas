import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class PtmScreen extends ConsumerWidget {
  const PtmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PTM meetings are derived from notices/events with type 'ptm' or 'meeting'
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'Parent-Teacher Meeting'),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const EmptyState(icon: Icons.people_outline_rounded, title: 'No PTM Info'),
        data: (notices) {
          final ptmNotices = notices.where((n) {
            final cat = (n.category ?? '').toLowerCase();
            final title = n.title.toLowerCase();
            return cat.contains('ptm') || cat.contains('meeting') ||
                title.contains('ptm') || title.contains('parent') || title.contains('meeting');
          }).toList();

          if (ptmNotices.isEmpty) return const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No PTM Scheduled',
            subtitle: 'Parent-Teacher meetings will be announced here.',
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Contact your class teacher or visit the school office to book your PTM slot.',
                      style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
                    ),
                  ),
                ]),
              ),

              const SectionHeader(title: 'Announcements'),
              ...ptmNotices.map((n) => _PtmCard(notice: n)),
            ],
          );
        },
      ),
    );
  }
}

class _PtmCard extends StatelessWidget {
  final NoticeModel notice;
  const _PtmCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.people_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(notice.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1))),
          if (notice.createdAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(8)),
              child: Text(DateFormat('d MMM').format(notice.createdAt!),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
        ]),
        if (notice.content.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(notice.content, style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.5)),
        ],
      ]),
    );
  }
}
