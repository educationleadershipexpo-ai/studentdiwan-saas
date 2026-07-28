import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// Real two-way messaging for the parent, over the SAME shared chat tables the
// desktop web app and the mobile teacher app use (chat_threads / chat_messages
// / chat_thread_states). A reply here reaches the teacher's inbox and desktop.
// Like the teacher app, we refresh on action + pull-to-refresh (no socket
// client is wired in mobile), so a sent message and its read-state are
// re-fetched immediately after posting.

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(parentChatThreadsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBackHeader(
        title: 'Messages',
        actions: [
          GestureDetector(
            onTap: () => _openNewConversation(context, ref),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)],
              ),
              child: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(
          message: 'Failed to load conversations',
          onRetry: () => ref.invalidate(parentChatThreadsProvider),
        ),
        data: (threads) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(parentChatThreadsProvider),
            child: threads.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.forum_outlined,
                        title: 'No Conversations Yet',
                        subtitle: 'Tap the compose icon to message your child\'s teachers or the school office.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: threads.length,
                    itemBuilder: (_, i) => _ThreadTile(thread: threads[i]),
                  ),
          );
        },
      ),
    );
  }

  static Future<void> _openNewConversation(BuildContext context, WidgetRef ref) async {
    final threadId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const NewConversationScreen()),
    );
    ref.invalidate(parentChatThreadsProvider);
    if (threadId != null && context.mounted) {
      final threads = await ref.read(parentChatThreadsProvider.future);
      final thread = threads.where((t) => t.id == threadId).firstOrNull;
      if (thread != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailedChatScreen(thread: thread)),
        );
        ref.invalidate(parentChatThreadsProvider);
      }
    }
  }
}

class _ThreadTile extends ConsumerWidget {
  final ChatThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailedChatScreen(thread: thread)),
        );
        ref.invalidate(parentChatThreadsProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46, height: 46,
            decoration: const BoxDecoration(color: AppColors.primaryExtraLight, shape: BoxShape.circle),
            child: Center(
              child: Text(thread.initials,
                  style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(thread.displayName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1)),
                ),
                if (thread.lastMessageAt != null)
                  Text(timeago.format(thread.lastMessageAt!, locale: 'en_short'),
                      style: const TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text(
                    (thread.lastMessage == null || thread.lastMessage!.isEmpty)
                        ? 'No messages yet'
                        : thread.lastMessage!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: thread.unread ? AppColors.text1 : AppColors.text3,
                      fontWeight: thread.unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (thread.unread) ...[
                  const SizedBox(width: 8),
                  Container(width: 9, height: 9,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Conversation detail ───────────────────────────────────────────────────────
class DetailedChatScreen extends ConsumerStatefulWidget {
  final ChatThread thread;
  const DetailedChatScreen({super.key, required this.thread});

  @override
  ConsumerState<DetailedChatScreen> createState() => _DetailedChatScreenState();
}

class _DetailedChatScreenState extends ConsumerState<DetailedChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark read on open so the inbox unread dot clears.
    final me = ref.read(authProvider).user;
    if (me != null) {
      ChatService.markThreadRead(threadId: widget.thread.id, myUid: me.uid);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(authProvider).user;
    if (me == null) return;

    setState(() => _sending = true);
    try {
      await ChatService.sendToThread(
        threadId: widget.thread.id,
        participants: widget.thread.participants,
        senderUid: me.uid,
        senderName: me.displayName.isNotEmpty ? me.displayName : 'Parent',
        text: text,
      );
      _controller.clear();
      ref.invalidate(parentChatMessagesProvider(widget.thread.id));
      ref.invalidate(parentChatThreadsProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t send. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;
    final myUid = me?.uid ?? '';
    final messagesAsync = ref.watch(parentChatMessagesProvider(widget.thread.id));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)],
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.text1),
          ),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: AppColors.primaryExtraLight, shape: BoxShape.circle),
            child: Center(
              child: Text(widget.thread.initials,
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(widget.thread.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text1)),
              if (widget.thread.otherRole.isNotEmpty)
                Text(_roleLabel(widget.thread.otherRole),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text3)),
            ]),
          ),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => ErrorState(
              message: 'Failed to load messages',
              onRetry: () => ref.invalidate(parentChatMessagesProvider(widget.thread.id)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Start the conversation',
                  subtitle: 'Send the first message below.',
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  final isMe = m.senderUid == myUid;
                  return _Bubble(message: m, isMe: isMe);
                },
              );
            },
          ),
        ),
        _Composer(controller: _controller, sending: _sending, onSend: _send),
      ]),
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'staff':
        return 'Teacher / School Office';
      case 'admin':
      case 'principal':
      case 'vice_principal':
        return 'School Office';
      default:
        return role;
    }
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(message.text,
                style: TextStyle(
                    fontSize: 13.5, height: 1.4,
                    color: isMe ? Colors.white : AppColors.text1)),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              DateFormat('d MMM · h:mm a').format(message.createdAt.toLocal()),
              style: const TextStyle(fontSize: 9.5, color: AppColors.text3, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: AppColors.text1),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.text3),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ── New conversation ──────────────────────────────────────────────────────────
class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  String _query = '';
  ChatContact? _selected;
  final _messageController = TextEditingController();
  bool _starting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final contact = _selected;
    final text = _messageController.text.trim();
    if (contact == null || text.isEmpty || _starting) return;
    final me = ref.read(authProvider).user;
    if (me == null) return;

    setState(() => _starting = true);
    try {
      final threadId = await ChatService.startDirectThread(
        myUid: me.uid,
        myName: me.displayName.isNotEmpty ? me.displayName : 'Parent',
        myEmail: me.email,
        myRole: 'parent',
        otherUid: contact.uid,
        otherName: contact.name,
        otherEmail: contact.email,
        otherRole: contact.role,
      );
      await ChatService.sendToThread(
        threadId: threadId,
        participants: [
          {'uid': me.uid, 'name': me.displayName, 'role': 'parent', 'email': me.email},
          {'uid': contact.uid, 'name': contact.name, 'role': contact.role, 'email': contact.email},
        ],
        senderUid: me.uid,
        senderName: me.displayName.isNotEmpty ? me.displayName : 'Parent',
        text: text,
      );
      if (mounted) Navigator.of(context).pop(threadId);
    } catch (_) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t start the conversation. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(parentChatContactsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: const AppBackHeader(title: 'New Message'),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => ErrorState(
          message: 'Failed to load contacts',
          onRetry: () => ref.invalidate(parentChatContactsProvider),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const EmptyState(
              icon: Icons.person_search_outlined,
              title: 'No Contacts Available',
              subtitle: 'Your child\'s teachers appear here once the school assigns them. You can always reach the school office.',
            );
          }
          final filtered = _query.isEmpty
              ? contacts
              : contacts.where((c) =>
                  c.name.toLowerCase().contains(_query.toLowerCase()) ||
                  c.subtitle.toLowerCase().contains(_query.toLowerCase())).toList();

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search teachers or school office…',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.text3, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final selected = _selected?.uid == c.uid;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = c),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryExtraLight : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: const BoxDecoration(color: AppColors.primaryExtraLight, shape: BoxShape.circle),
                          child: Center(
                            child: Text(c.initials,
                                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text1)),
                            if (c.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(c.subtitle,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.text3)),
                            ],
                          ]),
                        ),
                        if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ]),
                    ),
                  );
                },
              ),
            ),
            if (_selected != null)
              Container(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 14, color: AppColors.text1),
                        decoration: InputDecoration(
                          hintText: 'Message ${_selected!.name.split(' ').first}…',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.text3),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _starting ? null : _start,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: _starting
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
