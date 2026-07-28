import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class StudyMaterialsScreen extends ConsumerWidget {
  const StudyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));
    final matAsync = ref.watch(studyMaterialsProvider(kid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBackHeader(title: 'Study Materials · ${kid.firstName}'),
      body: matAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load study materials', onRetry: () => ref.invalidate(studyMaterialsProvider(kid))),
        data: (materials) {
          if (materials.isEmpty) return const EmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No Study Materials',
            subtitle: 'Shared notes, PDFs, and resources will appear here.',
          );

          // Group by subject
          final Map<String, List<StudyMaterial>> grouped = {};
          for (final m in materials) {
            final key = m.subject ?? 'General';
            grouped.putIfAbsent(key, () => []).add(m);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: grouped.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: entry.key),
                ...entry.value.map((m) => _MaterialCard(material: m)),
              ],
            )).toList(),
          );
        },
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final StudyMaterial material;
  const _MaterialCard({required this.material});

  IconData get _typeIcon {
    final t = material.type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (t.contains('video')) return Icons.play_circle_outline_rounded;
    if (t.contains('image') || t.contains('img')) return Icons.image_outlined;
    if (t.contains('doc') || t.contains('word')) return Icons.description_outlined;
    if (t.contains('ppt') || t.contains('slide')) return Icons.slideshow_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get _typeColor {
    final t = material.type.toLowerCase();
    if (t.contains('pdf')) return AppColors.red;
    if (t.contains('video')) return AppColors.blue;
    if (t.contains('ppt') || t.contains('slide')) return AppColors.amber;
    if (t.contains('doc')) return AppColors.blue;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(material.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1), maxLines: 2),
          const SizedBox(height: 3),
          Row(children: [
            if (material.type.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(material.type.toUpperCase(),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _typeColor, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 6),
            ],
            if (material.uploadedAt != null)
              Text(DateFormat('d MMM yyyy').format(material.uploadedAt!),
                style: const TextStyle(fontSize: 10, color: AppColors.text3)),
          ]),
        ])),
        if (material.fileUrl != null)
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(material.fileUrl!);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 18),
            ),
          ),
      ]),
    );
  }
}
