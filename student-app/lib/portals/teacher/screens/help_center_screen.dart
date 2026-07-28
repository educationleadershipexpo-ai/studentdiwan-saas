// ── Help Center (staff mobile portal) ────────────────────────────────────────
// Role-scoped in-app help: a getting-started guide for new users, searchable
// articles grouped by the categories the account's real role may see, and a
// real support-ticket flow (raise a ticket + My Tickets) backed by
// /api/data/support_tickets — genuine DB rows, no mock data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_client.dart';
import '../core/help_center.dart';
import '../core/rbac.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Guides & Articles'),
            Tab(text: 'Support'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ArticlesTab(
            role: role,
            searchCtrl: _searchCtrl,
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
          ),
          _SupportTab(uid: user?.uid ?? '', role: role),
        ],
      ),
    );
  }
}

// ── Tab 1: getting-started guide + searchable role-scoped articles ───────────
class _ArticlesTab extends StatelessWidget {
  final String? role;
  final TextEditingController searchCtrl;
  final String query;
  final ValueChanged<String> onQueryChanged;

  const _ArticlesTab({
    required this.role,
    required this.searchCtrl,
    required this.query,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = allowedCategories(role);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Role banner — the help you see is scoped to your real role.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help for ${roleLabel(role)}s',
                      style: GoogleFonts.inter(
                        color: context.cardColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Guides and answers tailored to your role.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search box.
        TextField(
          controller: searchCtrl,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search help articles…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      searchCtrl.clear();
                      onQueryChanged('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // New-user "getting started" guide, shown only when not searching.
        if (query.isEmpty) _NewUserGuideCard(role: role),
        if (query.isEmpty) const SizedBox(height: 20),

        // Articles grouped by allowed category.
        ..._buildCategorySections(context, categories),
      ],
    );
  }

  List<Widget> _buildCategorySections(
      BuildContext context, List<HelpCategory> categories) {
    final sections = <Widget>[];
    var anyResults = false;

    for (final cat in categories) {
      final articles = articlesInCategory(role, cat.id, query: query);
      if (articles.isEmpty) continue;
      anyResults = true;
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(cat.title, style: context.heading3),
      ));
      for (final a in articles) {
        sections.add(_ArticleTile(article: a));
      }
      sections.add(const SizedBox(height: 12));
    }

    if (!anyResults) {
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppColors.text3),
              const SizedBox(height: 12),
              Text(
                query.isEmpty
                    ? 'No articles available for your role yet.'
                    : 'No articles match "$query".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text3),
              ),
            ],
          ),
        ),
      ));
    }

    return sections;
  }
}

class _NewUserGuideCard extends StatelessWidget {
  final String? role;
  const _NewUserGuideCard({required this.role});

  @override
  Widget build(BuildContext context) {
    // Prefer the dedicated first-day checklist; fall back to the welcome tour.
    final guide = articlesFor(role).where((a) => a.id == 'first-day').isNotEmpty
        ? articlesFor(role).firstWhere((a) => a.id == 'first-day')
        : (articlesFor(role).isNotEmpty ? articlesFor(role).first : null);
    if (guide == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openArticle(context, guide),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryExtraLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New here? Start with this guide',
                      style: context.heading3),
                  const SizedBox(height: 2),
                  Text(
                    guide.summary,
                    style: const TextStyle(color: AppColors.text2, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final HelpArticle article;
  const _ArticleTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: const Icon(Icons.article_outlined, color: AppColors.primary),
        title: Text(article.title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text1, fontSize: 14)),
        subtitle: Text(article.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.text3, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
        onTap: () => _openArticle(context, article),
      ),
    );
  }
}

void _openArticle(BuildContext context, HelpArticle article) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => _ArticleDetailScreen(article: article),
  ));
}

// ── Article detail ───────────────────────────────────────────────────────────
class _ArticleDetailScreen extends StatelessWidget {
  final HelpArticle article;
  const _ArticleDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    final paragraphs = article.body.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text(article.title, style: context.heading1),
          const SizedBox(height: 6),
          Text(article.summary,
              style: const TextStyle(color: AppColors.text2, fontSize: 14, height: 1.4)),
          const Divider(height: 32),
          ...paragraphs.map((line) {
            final trimmed = line.trimLeft();
            if (trimmed.isEmpty) return const SizedBox(height: 12);
            if (trimmed.startsWith('• ')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(trimmed.substring(2),
                          style: const TextStyle(color: AppColors.text1, fontSize: 14, height: 1.5)),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(line,
                  style: const TextStyle(color: AppColors.text1, fontSize: 14, height: 1.55)),
            );
          }),
        ],
      ),
    );
  }
}

// ── Tab 2: raise a ticket + My Tickets (real /api/data/support_tickets) ──────
class _SupportTab extends StatefulWidget {
  final String uid;
  final String? role;
  const _SupportTab({required this.uid, required this.role});

  @override
  State<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<_SupportTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'General';
  bool _submitting = false;

  late Future<List<Map<String, dynamic>>> _ticketsFuture;

  static const _categories = [
    'General',
    'Account & Login',
    'Attendance',
    'Gradebook & Results',
    'Homework & Assignments',
    'Bug / Something broken',
    'Feature request',
  ];

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadTickets() {
    // Scope to the signed-in staff member's own tickets.
    return ApiClient.instance
        .getAll('support_tickets', params: {'uid': widget.uid});
  }

  void _refreshTickets() {
    setState(() => _ticketsFuture = _loadTickets());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.createRecord('support_tickets', {
        'subject': _subjectCtrl.text.trim(),
        'category': _category,
        'description': _descCtrl.text.trim(),
        'status': 'open',
        'raisedByUid': widget.uid,
        'uid': widget.uid,
        'raisedByRole': widget.role ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      _subjectCtrl.clear();
      _descCtrl.clear();
      setState(() => _category = 'General');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket submitted — we\'ll get back to you.'),
          backgroundColor: AppColors.green,
        ),
      );
      _refreshTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit ticket. Please try again.'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Raise a ticket', style: context.heading2),
        const SizedBox(height: 4),
        const Text(
          'Describe your problem and our support team will follow up.',
          style: TextStyle(color: AppColors.text3, fontSize: 12.5),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subjectCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please add a subject' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'General'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please describe the issue (at least 10 characters)'
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_submitting ? 'Submitting…' : 'Submit ticket'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My tickets', style: context.heading2),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _refreshTickets,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 4),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _ticketsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final tickets = snap.data ?? [];
            if (tickets.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryExtraLight),
                ),
                child: const Center(
                  child: Text(
                    'You haven\'t raised any tickets yet.',
                    style: TextStyle(color: AppColors.text3),
                  ),
                ),
              );
            }
            // Newest first.
            tickets.sort((a, b) => (b['createdAt']?.toString() ?? '')
                .compareTo(a['createdAt']?.toString() ?? ''));
            return Column(
              children: tickets.map((t) => _TicketCard(ticket: t)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final status = (ticket['status']?.toString() ?? 'open').toLowerCase();
    final subject = ticket['subject']?.toString() ?? 'Untitled';
    final category = ticket['category']?.toString() ?? '';
    final createdAt = ticket['createdAt']?.toString() ?? '';

    Color statusColor;
    switch (status) {
      case 'resolved':
      case 'closed':
        statusColor = AppColors.green;
        break;
      case 'in_progress':
      case 'in progress':
        statusColor = AppColors.amber;
        break;
      default:
        statusColor = AppColors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(subject,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.text1, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(category,
                style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_formatDate(createdAt),
                style: const TextStyle(color: AppColors.text3, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return 'Raised $y-$m-$d $hh:$mm';
  }
}
