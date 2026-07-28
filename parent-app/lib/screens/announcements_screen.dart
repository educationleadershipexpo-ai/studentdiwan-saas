import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  static const _colors = [AppColors.red, AppColors.amber, AppColors.green, AppColors.blue, AppColors.primary];
  static const _catColors = {
    'urgent': AppColors.red, 'academic': AppColors.blue,
    'event': AppColors.green, 'general': AppColors.primary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'Announcements'),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const EmptyState(icon: Icons.campaign_outlined, title: 'No Announcements'),
        data: (notices) {
          if (notices.isEmpty) return const EmptyState(icon: Icons.campaign_outlined, title: 'No Announcements', subtitle: 'School announcements will appear here.');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: notices.length,
            itemBuilder: (_, i) {
              final n = notices[i];
              final color = _colors[i % _colors.length];
              final catColor = n.category != null ? (_catColors[n.category!.toLowerCase()] ?? AppColors.primary) : color;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1))),
                    if (n.category != null) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                      child: Text(n.category!.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: catColor)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(n.content, style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.5)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (n.createdAt != null) DateFormat('d MMM yyyy').format(n.createdAt!),
                      if (n.author != null) n.author!,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 10, color: AppColors.text3),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
