import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  static const _avatarColors = [
    [Color(0xFF74B9FF), Color(0xFF0984E3)],
    [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
    [Color(0xFF55EFC4), Color(0xFF00B894)],
    [Color(0xFFFF7675), Color(0xFFD63031)],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    final selected = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: const AppBackHeader(title: 'My Children'),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load children', onRetry: () => ref.invalidate(childrenProvider)),
        data: (kids) {
          if (kids.isEmpty) return const EmptyState(icon: Icons.people_outline_rounded, title: 'No Children Linked', subtitle: 'Contact the school admin to link students to your account.');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: kids.length,
            itemBuilder: (_, i) {
              final kid = kids[i];
              final isSelected = selected?.id == kid.id;
              final colors = _avatarColors[i % _avatarColors.length];
              return GestureDetector(
                onTap: () {
                  selectChild(ref, kid);
                  context.pop();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 14)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                      ),
                      child: Center(child: Text(kid.initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(kid.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text1)),
                      const SizedBox(height: 3),
                      Text('${kid.gradeLabel}${kid.rollNumber.isNotEmpty ? ' · Roll ${kid.rollNumber}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                    ])),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
