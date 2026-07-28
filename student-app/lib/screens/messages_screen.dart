import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Teachers, 2 = Announcements
  final List<String> _filters = ['All', 'Teachers', 'Announcements'];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(studentMessagesProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Messages Inbox',
            subtitle: 'Chat with your teachers and read system announcements',
            showBackButton: false,
          ),
          const SizedBox(height: 16),

          // Filters Tab Bar
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
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

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: TextStyle(color: AppColors.text3),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Message Feed List
          Expanded(
            child: messagesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 75),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (list) {
                final filtered = list.where((msg) {
                  final matchesSearch = msg.senderName.toLowerCase().contains(_searchQuery) ||
                      msg.content.toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;

                  if (_selectedFilter == 1) return msg.senderRole.contains('Teacher');
                  if (_selectedFilter == 2) return !msg.senderRole.contains('Teacher');
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No conversations found.', style: TextStyle(color: AppColors.text3)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final hasUnread = item.unreadCount > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryExtraLight),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryExtraLight,
                          child: Text(item.initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.senderName, style: context.heading3.copyWith(fontSize: 14)),
                            Text(
                              item.timestamp != null
                                  ? '${item.timestamp!.hour}:${item.timestamp!.minute.toString().padLeft(2, '0')}'
                                  : '',
                              style: context.bodySmall,
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.content,
                                style: context.bodySmall.copyWith(
                                  color: hasUnread ? AppColors.text1 : AppColors.text3,
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: Text(
                                  '${item.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          // Open detailed chat screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailedChatScreen(conversation: item),
                            ),
                          );
                        },
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

// ── Message Detail (read-only announcement / notice) ────────────────────────
// The student inbox surfaces school announcements and notices, which are
// one-way. We show the real message content — no fabricated replies or a
// compose box that has no backend to send to.
class DetailedChatScreen extends StatelessWidget {
  final MessageModel conversation;
  const DetailedChatScreen({super.key, required this.conversation});

  String _fmtTimestamp(DateTime? ts) {
    if (ts == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
    final ampm = ts.hour < 12 ? 'AM' : 'PM';
    return '${ts.day} ${months[ts.month - 1]} ${ts.year} · $h:${ts.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final when = _fmtTimestamp(conversation.timestamp);
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (conversation.senderRole.isNotEmpty)
              Text(conversation.senderRole, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryExtraLight,
                  child: Text(conversation.initials,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(conversation.senderName, style: context.heading3.copyWith(fontSize: 15)),
                      if (when.isNotEmpty)
                        Text(when, style: context.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryExtraLight),
              ),
              child: Text(
                conversation.content.isEmpty ? 'No content.' : conversation.content,
                style: const TextStyle(color: AppColors.text1, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
