import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/socket_service.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _selectedFilter = 0; // 0=All, 1=Students, 2=Parents, 3=Staff
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Students', 'Parents', 'Staff'];

  @override
  void initState() {
    super.initState();
    // Initialize Socket.IO for real-time messaging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SocketService.instance.init();
    });
  }

  @override
  void dispose() {
    // Keep socket alive for other screens
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use real-time provider that merges initial data + socket updates
    final threadsAsync = ref.watch(chatThreadsRealtimeProvider);
    final myUid = ref.watch(authProvider).user?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Messages Inbox',
            subtitle: 'Communicate with students, parents, and colleagues',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
              onPressed: () => _showContactsSheet(context),
            ),
          ),
          const SizedBox(height: 16),

          // Connection Status Indicator
          _buildConnectionStatus(),

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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

          // Search Bar
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

          // Conversation List
          Expanded(
            child: threadsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonLoader(width: double.infinity, height: 75),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error loading inbox: $err')),
              data: (list) {
                // Filter messages
                final filtered = list.where((thread) {
                  // Find other participant
                  final other = thread.participants.firstWhere(
                    (p) => p.uid != myUid,
                    orElse: () => const ParticipantModel(uid: '', name: 'Deleted User', role: '', email: ''),
                  );

                  final matchesSearch = other.name.toLowerCase().contains(_searchQuery) ||
                      (thread.lastMessage ?? '').toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;

                  if (_selectedFilter == 1) return other.role == 'student';
                  if (_selectedFilter == 2) return other.role == 'parent';
                  if (_selectedFilter == 3) return other.role == 'staff' || other.role == 'teacher' || other.role == 'admin';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.text3.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 0 ? 'No conversations yet' : 'No conversations in this category',
                          style: context.body.copyWith(color: AppColors.text3),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedFilter == 0)
                          ElevatedButton.icon(
                            onPressed: () => _showContactsSheet(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Start New Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final thread = filtered[index];
                    final other = thread.participants.firstWhere(
                      (p) => p.uid != myUid,
                      orElse: () => const ParticipantModel(uid: '', name: 'Deleted User', role: '', email: ''),
                    );

                    final isUnread = _isThreadUnread(thread, myUid);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isUnread ? AppColors.primary : AppColors.primaryExtraLight, width: isUnread ? 2 : 1),
                        boxShadow: isUnread ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ] : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryExtraLight,
                              child: Text(
                                other.initials,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                              ),
                            ),
                            if (isUnread)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                other.name,
                                style: context.heading3.copyWith(
                                  fontSize: 15,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              thread.lastMessageAt != null
                                  ? _formatChatTime(thread.lastMessageAt!)
                                  : '',
                              style: context.bodySmall?.copyWith(
                                color: isUnread ? AppColors.primary : AppColors.text3,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  thread.lastMessage ?? 'No messages yet',
                                  style: context.bodySmall.copyWith(
                                    color: isUnread ? AppColors.text1 : AppColors.text3,
                                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildRoleBadge(other.role),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailedChatScreen(thread: thread),
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

  Widget _buildConnectionStatus() {
    return Consumer(
      builder: (context, ref, _) {
        final isConnected = SocketService.instance.isConnected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isConnected ? 28 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isConnected
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    String label;

    switch (role.toLowerCase()) {
      case 'student':
        bgColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        label = 'Student';
        break;
      case 'parent':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Parent';
        break;
      case 'staff':
      case 'teacher':
      case 'admin':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Staff';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = 'Other';
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    if (local.day == now.day && local.month == now.month && local.year == now.year) {
      return DateFormat('hh:mm a').format(local);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.day == yesterday.day && local.month == yesterday.month && local.year == yesterday.year) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(local);
  }

  bool _isThreadUnread(ChatThreadModel thread, String myUid) {
    if (thread.lastMessageAt == null) return false;
    if (thread.lastSenderUid == myUid) return false; // My own message
    // TODO: Add proper unread tracking with ChatThreadState
    return false;
  }

  // ── Contacts Selection bottom sheet ────────────────────────────────────────
  void _showContactsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return _ContactsSelectorWidget(scrollController: scrollController);
          },
        );
      },
    );
  }
}

// Helper stateful widget inside contact sheet
class _ContactsSelectorWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _ContactsSelectorWidget({required this.scrollController});

  @override
  ConsumerState<_ContactsSelectorWidget> createState() => _ContactsSelectorWidgetState();
}

class _ContactsSelectorWidgetState extends ConsumerState<_ContactsSelectorWidget> {
  int _contactFilter = 0; // 0=Students, 1=Parents, 2=Staff
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsProvider);
    final staffAsync = ref.watch(staffProvider);
    final myUid = ref.watch(authProvider).user?.uid ?? '';
    final myUser = ref.watch(authProvider).user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Message', style: context.heading2),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),

          // Filters Tab
          Row(
            children: [
              _buildTabButton('Students', 0),
              const SizedBox(width: 8),
              _buildTabButton('Parents', 1),
              const SizedBox(width: 8),
              _buildTabButton('Colleagues', 2),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search contact...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.text3),
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
          const SizedBox(height: 16),

          // Contacts list
          Expanded(
            child: _contactFilter == 2
                ? staffAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (staffList) {
                      final filtered = staffList.where((s) {
                        final name = s['name']?.toString().toLowerCase() ?? '';
                        return name.contains(_query) && s['id'] != myUid;
                      }).toList();

                      return ListView.builder(
                        controller: widget.scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final name = item['name']?.toString() ?? 'Colleague';
                          final email = item['email']?.toString() ?? '';
                          final uid = item['id']?.toString() ?? item['uid']?.toString() ?? '';
                          final role = item['role']?.toString() ?? 'staff';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryExtraLight,
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(color: AppColors.primary)),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$role · $email'),
                            onTap: () => _startChat(uid, name, role, email, myUid, myUser),
                          );
                        },
                      );
                    },
                  )
                : studentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (students) {
                      if (_contactFilter == 0) {
                        // Students listing
                        final filtered = students.where((s) {
                          final name = s['name']?.toString().toLowerCase() ?? '';
                          return name.contains(_query);
                        }).toList();

                        return ListView.builder(
                          controller: widget.scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final name = item['name']?.toString() ?? 'Student';
                            final email = item['email']?.toString() ?? '';
                            final uid = item['id']?.toString() ?? '';
                            final grade = item['grade']?.toString() ?? '';
                            final section = item['section']?.toString() ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryExtraLight,
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: AppColors.primary)),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Grade $grade-$section · $email'),
                              onTap: () => _startChat(uid, name, 'student', email, myUid, myUser),
                            );
                          },
                        );
                      } else {
                        // Parents listing
                        final List<Map<String, dynamic>> parentsList = [];
                        final seenParents = <String>{};

                        for (final s in students) {
                          final fEmail = s['fatherEmail']?.toString().trim().toLowerCase() ?? '';
                          final fName = s['fatherName']?.toString().trim() ?? '';
                          final studentName = s['name']?.toString() ?? '';
                          final studentId = s['id']?.toString() ?? '';

                          if (fEmail.isNotEmpty && !seenParents.contains(fEmail)) {
                            seenParents.add(fEmail);
                            parentsList.add({
                              'name': fName.isNotEmpty ? fName : '$studentName\'s Father',
                              'email': fEmail,
                              'uid': '$studentId-parent',
                              'student': studentName,
                            });
                          }

                          final mEmail = s['motherEmail']?.toString().trim().toLowerCase() ?? '';
                          final mName = s['motherName']?.toString().trim() ?? '';
                          if (mEmail.isNotEmpty && !seenParents.contains(mEmail)) {
                            seenParents.add(mEmail);
                            parentsList.add({
                              'name': mName.isNotEmpty ? mName : '$studentName\'s Mother',
                              'email': mEmail,
                              'uid': '$studentId-parent',
                              'student': studentName,
                            });
                          }
                        }

                        final filtered = parentsList.where((p) {
                          final name = p['name'].toLowerCase();
                          final child = p['student'].toLowerCase();
                          return name.contains(_query) || child.contains(_query);
                        }).toList();

                        return ListView.builder(
                          controller: widget.scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryExtraLight,
                                child: Text(item['name'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                              ),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Parent of ${item['student']} · ${item['email']}'),
                              onTap: () => _startChat(item['uid'], item['name'], 'parent', item['email'], myUid, myUser),
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final active = _contactFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _contactFilter = index),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startChat(String contactUid, String contactName, String contactRole, String contactEmail, String myUid, UserModel? myUser) async {
    if (myUser == null) return;
    Navigator.pop(context); // Close contact selector sheet

    final sortedUids = [myUid, contactUid]..sort();
    final threadId = 'dm_${sortedUids.join("_")}';

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Check if thread already exists in the provider list
      final threads = ref.read(chatThreadsProvider).value ?? [];
      ChatThreadModel? existingThread;
      for (final t in threads) {
        if (t.id == threadId) {
          existingThread = t;
          break;
        }
      }

      if (existingThread == null) {
        // Create the thread record in the database
        final threadData = {
          'id': threadId,
          'type': 'direct',
          'name': contactName,
          'participants': [
            {
              'uid': myUid,
              'name': myUser.displayName,
              'role': myUser.role,
              'email': myUser.email,
            },
            {
              'uid': contactUid,
              'name': contactName,
              'role': contactRole,
              'email': contactEmail,
            }
          ],
          'createdBy': myUid,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'lastMessage': 'No messages yet',
          'lastMessageAt': DateTime.now().toUtc().toIso8601String(),
          'lastSenderUid': myUid,
        };

        await ApiClient.instance.createRecord(AppConstants.chatThreads, threadData);
        ref.invalidate(chatThreadsProvider);
        
        // Build thread model locally
        existingThread = ChatThreadModel.fromJson(threadData);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedChatScreen(thread: existingThread!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }
}

// ── Detailed Chat Screen with Real-time Message Updates ─────────────────────────
class DetailedChatScreen extends ConsumerStatefulWidget {
  final ChatThreadModel thread;
  const DetailedChatScreen({super.key, required this.thread});

  @override
  ConsumerState<DetailedChatScreen> createState() => _DetailedChatScreenState();
}

class _DetailedChatScreenState extends ConsumerState<DetailedChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _threadSubscription;

  @override
  void initState() {
    super.initState();
    _listenForRealTimeUpdates();
    _scrollToBottom();
  }

  void _listenForRealTimeUpdates() {
    final socket = SocketService.instance;
    
    // Listen for new messages in real-time
    _messageSubscription = socket.onNewMessage.listen((data) {
      if (data['threadId'] == widget.thread.id) {
        // New message for this thread - invalidate to refetch
        debugPrint('[DetailedChatScreen] Real-time message received for current thread');
        ref.invalidate(chatMessagesProvider(widget.thread.id));
        ref.invalidate(chatThreadsProvider);
        _scrollToBottom();
      }
    });

    // Listen for thread updates (new thread created, etc.)
    _threadSubscription = socket.onThreadUpdate.listen((data) {
      debugPrint('[DetailedChatScreen] Thread update: $data');
      ref.invalidate(chatThreadsProvider);
    });

    // Join the thread room for real-time updates
    socket.joinThread(widget.thread.id);

    // Mark thread as read
    socket.markThreadRead(widget.thread.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _threadSubscription?.cancel();
    SocketService.instance.leaveThread(widget.thread.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    final myUser = ref.read(authProvider).user;
    if (myUser == null) return;

    setState(() => _sending = true);
    final now = DateTime.now().toUtc();
    final messageId = 'msg_${now.millisecondsSinceEpoch}_${widget.thread.id}';

    final messageData = {
      'id': messageId,
      'threadId': widget.thread.id,
      'senderUid': myUser.uid,
      'senderName': myUser.displayName,
      'text': text,
      'createdAt': now.toIso8601String(),
    };

    try {
      // 1. Save chat message
      await ApiClient.instance.createRecord(AppConstants.messages, messageData);

      // 2. Update chat thread summary
      final updatedThread = {
        'lastMessage': text,
        'lastMessageAt': now.toIso8601String(),
        'lastSenderUid': myUser.uid,
      };
      await ApiClient.instance.updateRecord(AppConstants.chatThreads, widget.thread.id, updatedThread);

      // 3. Emit via Socket.IO for real-time delivery
      SocketService.instance.sendMessage(messageData);

      _messageController.clear();
      _scrollToBottom();
      
      // Invalidate providers to trigger fresh fetch
      ref.invalidate(chatMessagesProvider(widget.thread.id));
      ref.invalidate(chatThreadsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.thread.id));
    final myUid = ref.watch(authProvider).user?.uid ?? '';
    
    final other = widget.thread.participants.firstWhere(
      (p) => p.uid != myUid,
      orElse: () => const ParticipantModel(uid: '', name: 'Deleted User', role: '', email: ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(other.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                Text(other.role.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final isConnected = SocketService.instance.isConnected;
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bubble Chat Feed
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading messages: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: context.heading3.copyWith(color: AppColors.text2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start the conversation with ${other.name}',
                          style: context.bodySmall.copyWith(color: AppColors.text3),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == myUid;

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
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && widget.thread.type == 'group')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg.senderName,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            Text(
                              msg.text,
                              style: TextStyle(color: isMe ? Colors.white : AppColors.text1, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.createdAt != null
                                      ? DateFormat('hh:mm a').format(msg.createdAt!.toLocal())
                                      : '',
                                  style: TextStyle(color: isMe ? Colors.white60 : AppColors.text3, fontSize: 10),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 14,
                                    color: Colors.white60,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                    onPressed: () {
                      // TODO: Add file attachment
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primaryExtraLight),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    backgroundColor: _sending ? AppColors.primary.withOpacity(0.6) : AppColors.primary,
                    onPressed: _sending ? null : _sendMessage,
                    child: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
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