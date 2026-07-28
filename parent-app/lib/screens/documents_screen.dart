import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final docsAsync = ref.watch(documentsProvider(kid.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBackHeader(title: 'Documents · ${kid.firstName}'),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load documents', onRetry: () => ref.invalidate(documentsProvider(kid.id))),
        data: (documents) {
          if (documents.isEmpty) return const EmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No Documents',
            subtitle: 'Student documents like certificates and ID cards will appear here.',
          );

          // Group by category/type
          final Map<String, List<StudentDocument>> grouped = {};
          for (final d in documents) {
            grouped.putIfAbsent(d.documentType, () => []).add(d);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: grouped.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: entry.key),
                ...entry.value.map((d) => _DocCard(doc: d)),
              ],
            )).toList(),
          );
        },
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final StudentDocument doc;
  const _DocCard({required this.doc});

  IconData get _icon {
    final t = doc.documentType.toLowerCase();
    if (t.contains('id') || t.contains('card')) return Icons.badge_outlined;
    if (t.contains('cert') || t.contains('award')) return Icons.workspace_premium_outlined;
    if (t.contains('admit') || t.contains('hall')) return Icons.confirmation_number_outlined;
    if (t.contains('fee') || t.contains('receipt')) return Icons.receipt_long_outlined;
    if (t.contains('result') || t.contains('mark')) return Icons.grade_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get _statusColor {
    final s = (doc.status ?? '').toLowerCase();
    if (s == 'verified' || s == 'approved') return AppColors.green;
    if (s == 'pending') return AppColors.amber;
    if (s == 'rejected') return AppColors.red;
    return AppColors.text3;
  }

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doc.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1), maxLines: 2),
          const SizedBox(height: 3),
          Row(children: [
            Text(doc.documentType, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
            if (doc.uploadedAt != null) ...[
              const Text(' · ', style: TextStyle(color: AppColors.text3)),
              Text(DateFormat('d MMM yyyy').format(doc.uploadedAt!),
                style: const TextStyle(fontSize: 10, color: AppColors.text3)),
            ],
          ]),
          if (doc.status != null) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
              child: Text(doc.status!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor)),
            ),
          ],
        ])),
        if (doc.fileUrl != null)
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(doc.fileUrl!);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 16),
            ),
          ),
      ]),
    );
  }
}
