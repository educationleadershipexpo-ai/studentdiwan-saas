import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

// ── Messages Inbox (shared chat model — mirrors the desktop web app) ─────────
// Reads the SAME server-backed `chat_threads` / `chat_messages` tables the
// desktop `Messages.tsx` uses, so a teacher sees the exact same conversations
// and information on mobile as on desktop. Only the layout is mobile-tailored.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _MessagesView();
  }
}

class _MessagesView extends ConsumerStatefulWidget {
  const _MessagesView();

  @override
  ConsumerState<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends ConsumerState<_MessagesView> {
  // Filters mirror the desktop tiers: everyone, colleagues, students, parents.
  int _selectedFilter = 0;
  String _searchQuery = '';

  static const List<String> _filters = ['All', 'Staff', 'Students', 'Parents'];

  Future<void> _openNewConversation() async {
    final threadId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const NewConversationScreen()),
    );
    ref.invalidate(teacherChatThreadsProvider);
    if (threadId != null && mounted) {
      final threads = await ref.read(teacherChatThreadsProvider.future);
      final t = threads.where((x) => x.id == threadId).cast<ChatThread?>().firstWhere(
            (x) => x != null,
            orElse: () => null,
          );
      if (t != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailedChatScreen(thread: t)),
        );
      }
    }
  }

  // Which filter tab a thread belongs to (by the OTHER participant's tier).
  bool _matchesFilter(ChatThread t) {
    switch (_selectedFilter) {
      case 1:
        return _tier(t.otherRole) == 'staff';
      case 2:
        return _tier(t.otherRole) == 'student';
      case 3:
        return _tier(t.otherRole) == 'parent';
      default:
        return true;
    }
  }

  // Collapse the many DB roles into the four messaging tiers (matches web).
  static String _tier(String role) {
    final r = role.toLowerCase();
    if (r.contains('parent') || r.contains('guardian')) return 'parent';
    if (r.contains('student')) return 'student';
    if (r == 'admin' || r == 'principal' || r == 'vice_principal') return 'admin';
    return 'staff'; // teacher / class_teacher / staff / coordinator / etc.
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(teacherChatThreadsProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Messages Inbox',
            subtitle: 'Communicate with students, parents, and colleagues',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
              tooltip: 'New message',
              onPressed: _openNewConversation,
            ),
          ),
          const SizedBox(height: 16),

          // Filter chips
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
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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

          // Search
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
                        hintText: 'Search conversations...',
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

          Expanded(
            child: threadsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 75),
                ),
              ),
              error: (err, _) => _ErrorState(
                onRetry: () => ref.invalidate(teacherChatThreadsProvider),
              ),
              data: (threads) {
                final filtered = threads.where((t) {
                  if (!_matchesFilter(t)) return false;
                  if (_searchQuery.isEmpty) return true;
                  final name = t.displayName.toLowerCase();
                  final last = (t.lastMessage ?? '').toLowerCase();
                  return name.contains(_searchQuery) || last.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(onNew: _openNewConversation);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(teacherChatThreadsProvider);
                    await ref.read(teacherChatThreadsProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _ThreadTile(thread: filtered[index]),
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

// ── One conversation row ─────────────────────────────────────────────────────
class _ThreadTile extends ConsumerWidget {
  final ChatThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = thread.unread;
    final preview = (thread.lastMessage ?? '').isEmpty
        ? 'No messages yet'
        : thread.lastMessage!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unread ? AppColors.primary : AppColors.primaryExtraLight,
          width: unread ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: thread.type == 'group'
                  ? AppColors.green.withValues(alpha: 0.15)
                  : AppColors.primaryExtraLight,
              child: thread.type == 'group'
                  ? const Icon(Icons.groups_rounded, color: AppColors.green)
                  : Text(
                      thread.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            if (unread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                thread.displayName,
                style: context.heading3.copyWith(
                  fontSize: 14,
                  fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _relTime(thread.lastMessageAt),
              style: context.bodySmall.copyWith(
                color: unread ? AppColors.primary : AppColors.text3,
                fontWeight: unread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            preview,
            style: context.bodySmall.copyWith(
              color: unread ? AppColors.text1 : AppColors.text3,
              fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailedChatScreen(thread: thread)),
        ),
      ),
    );
  }
}

// Short relative time for the inbox list (no fake fallbacks — blank if unknown).
String _relTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final local = t.toLocal();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24 && now.day == local.day) {
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '$h:${local.minute.toString().padLeft(2, '0')} $ampm';
  }
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[local.weekday - 1];
  }
  return '${local.day}/${local.month}';
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text('No conversations yet', style: context.heading3),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with a student, parent, or colleague.',
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(color: AppColors.text3),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('New Message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.text3),
          const SizedBox(height: 12),
          Text('Could not load messages', style: context.heading3),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Detailed Chat Screen ─────────────────────────────────────────────────────
// Loads the REAL shared message history for a thread and appends new messages
// into the same `chat_messages` table the desktop reads.
class DetailedChatScreen extends ConsumerStatefulWidget {
  final ChatThread thread;
  const DetailedChatScreen({super.key, required this.thread});

  @override
  ConsumerState<DetailedChatScreen> createState() => _DetailedChatScreenState();
}

class _DetailedChatScreenState extends ConsumerState<DetailedChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark the thread as read for me the moment I open it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final me = ref.read(authProvider).user;
    if (me == null) return;
    try {
      await ChatService.markThreadRead(threadId: widget.thread.id, myUid: me.uid);
      ref.invalidate(teacherChatThreadsProvider);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(authProvider).user;
    if (me == null) return;

    setState(() => _sending = true);
    _messageController.clear();
    try {
      await ChatService.sendToThread(
        threadId: widget.thread.id,
        participants: widget.thread.participants,
        senderUid: me.uid,
        senderName: me.displayName,
        text: text,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      ref.invalidate(chatMessagesProvider(widget.thread.id));
      ref.invalidate(teacherChatThreadsProvider);
      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;
    final myUid = me?.uid ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.thread.id));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryExtraLight,
              child: widget.thread.type == 'group'
                  ? const Icon(Icons.groups_rounded, size: 20, color: AppColors.primary)
                  : Text(
                      widget.thread.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.thread.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _roleLabel(widget.thread.otherRole),
                    style: const TextStyle(fontSize: 12, color: AppColors.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load messages: $e', textAlign: TextAlign.center),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSay hello 👋',
                      textAlign: TextAlign.center,
                      style: context.bodySmall.copyWith(color: AppColors.text3),
                    ),
                  );
                }
                _scrollToBottomSoon();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.senderUid == myUid;
                    return _Bubble(
                      text: m.text,
                      time: _fmtTime(m.createdAt),
                      isMe: isMe,
                      showSender: widget.thread.type == 'group' && !isMe,
                      senderName: m.senderName,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _messageController,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool showSender;
  final String senderName;
  const _Bubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.showSender,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : const Color(0xFFF1F3F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSender)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : AppColors.text1, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: isMe ? Colors.white60 : AppColors.text3, fontSize: 10),
            ),
          ],
        ),
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: context.cardColor,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              backgroundColor: AppColors.primary,
              onPressed: sending ? null : onSend,
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtTime(DateTime t) {
  final d = t.toLocal();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
}

String _roleLabel(String role) {
  if (role.isEmpty) return 'Conversation';
  final r = role.toLowerCase();
  if (r.contains('parent') || r.contains('guardian')) return 'Parent';
  if (r.contains('student')) return 'Student';
  // Prettify: class_teacher -> Class Teacher
  return role
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ── New Conversation Composer ────────────────────────────────────────────────
// Picks a real recipient the teacher is allowed to message, then finds-or-creates
// a SHARED thread (deterministic dm_ id, matching desktop) and posts the first
// message. Returns the thread id so the caller can open it.
class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  final _searchCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _audience = 0; // 0 = Students, 1 = Staff
  String _search = '';
  ChatContact? _recipient;
  bool _sending = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_recipient == null) {
      _toast('Please choose a recipient');
      return;
    }
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) {
      _toast('Please type a message');
      return;
    }
    final me = ref.read(authProvider).user;
    if (me == null) {
      _toast('Session expired, please sign in again');
      return;
    }
    final r = _recipient!;

    setState(() => _sending = true);
    try {
      final threadId = await ChatService.startDirectThread(
        myUid: me.uid,
        myName: me.displayName,
        myEmail: me.email,
        myRole: me.role,
        otherUid: r.uid,
        otherName: r.name,
        otherEmail: r.email,
        otherRole: r.role,
      );
      await ChatService.sendToThread(
        threadId: threadId,
        participants: [
          {'uid': me.uid, 'name': me.displayName, 'role': me.role, 'email': me.email},
          {'uid': r.uid, 'name': r.name, 'role': r.role, 'email': r.email},
        ],
        senderUid: me.uid,
        senderName: me.displayName,
        text: text,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.pop(context, threadId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _toast('Failed to send: $e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(chatContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Students'), icon: Icon(Icons.school_outlined)),
                ButtonSegment(value: 1, label: Text('Staff'), icon: Icon(Icons.badge_outlined)),
              ],
              selected: {_audience},
              onSelectionChanged: (s) => setState(() {
                _audience = s.first;
                _recipient = null;
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search recipient…',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load recipients: $e')),
              data: (all) {
                final wantStaff = _audience == 1;
                final list = all.where((c) {
                  final isStaff = c.role == 'staff';
                  if (wantStaff != isStaff) return false;
                  return _search.isEmpty || c.name.toLowerCase().contains(_search);
                }).toList();
                if (list.isEmpty) {
                  return const Center(child: Text('No recipients found.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    final selected = _recipient?.uid == c.uid;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryExtraLight,
                        child: Text(
                          c.initials,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(c.name),
                      subtitle: Text(c.subtitle),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      selected: selected,
                      onTap: () => setState(() => _recipient = c),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _messageCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your message…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_sending ? 'Sending…' : 'Send Message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
