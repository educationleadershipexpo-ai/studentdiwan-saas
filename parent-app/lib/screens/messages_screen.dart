import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgsAsync = ref.watch(messagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBackHeader(
        title: 'Messages',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compose message — coming soon'))),
            ),
          ),
        ],
      ),
      body: msgsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(message: 'Failed to load messages', onRetry: () => ref.invalidate(messagesProvider)),
        data: (messages) {
          if (messages.isEmpty) return const EmptyState(icon: Icons.mail_outline_rounded, title: 'No Messages', subtitle: 'Your inbox is empty.');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: messages.length,
            itemBuilder: (_, i) => _MessageCard(message: messages[i]),
          );
        },
      ),
    );
  }
}

class _MessageCard extends StatefulWidget {
  final MessageModel message;
  const _MessageCard({required this.message});

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  bool _expanded = false;

  static const _colors = [
    [AppColors.primaryExtraLight, AppColors.primary],
    [AppColors.redLight, AppColors.red],
    [AppColors.amberLight, AppColors.amber],
    [AppColors.greenLight, AppColors.green],
    [AppColors.blueLight, AppColors.blue],
  ];

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final colorIdx = msg.fromName.hashCode.abs() % _colors.length;
    final bg = _colors[colorIdx][0];
    final fg = _colors[colorIdx][1];

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(child: Text(msg.initials, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(msg.fromName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1))),
                if (!msg.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 2),
              if (msg.subject.isNotEmpty)
                Text(msg.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
            ])),
            const SizedBox(width: 8),
            Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16, color: AppColors.text3),
          ]),
          const SizedBox(height: 6),
          Text(
            msg.body,
            style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.5),
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            msg.timestamp != null ? timeago.format(msg.timestamp!) : '',
            style: const TextStyle(fontSize: 10, color: AppColors.text3),
          ),
        ]),
      ),
    );
  }
}
