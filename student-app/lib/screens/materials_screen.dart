import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Notes, 2 = Videos, 3 = Papers
  final List<String> _filters = ['All', 'Notes', 'Videos', 'Papers'];
  final Set<String> _openingIds = {};

  // Open the real file the teacher uploaded (fileUrl/downloadUrl) in the
  // device's browser/viewer. No fake progress bar — either there's a URL to
  // open or we tell the student it isn't available.
  Future<void> _openMaterial(String itemId, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This material has no downloadable file yet.')),
      );
      return;
    }
    setState(() => _openingIds.add(itemId));
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this file.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this file.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingIds.remove(itemId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(studentMaterialsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Study Materials',
            subtitle: 'Access digital lecture notes, videos, and question papers offline',
            showBackButton: false,
          ),
          const SizedBox(height: 16),

          // Filters selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSel = _selectedFilter == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.primaryExtraLight,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSel ? Colors.white : AppColors.text2,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Materials Feed
          Expanded(
            child: materialsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 70),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (list) {
                final filtered = list.where((item) {
                  if (_selectedFilter == 0) return true;
                  return item.type.toLowerCase() == _filters[_selectedFilter].toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No learning documents in this category.', style: TextStyle(color: AppColors.text3)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isOpening = _openingIds.contains(item.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryExtraLight),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: context.heading3.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  item.size.isEmpty ? item.type : '${item.type} · ${item.size}',
                                  style: context.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Open the real uploaded file.
                          if (isOpening)
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          else
                            IconButton(
                              tooltip: 'Open',
                              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 24),
                              onPressed: () => _openMaterial(item.id, item.downloadUrl),
                            )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
