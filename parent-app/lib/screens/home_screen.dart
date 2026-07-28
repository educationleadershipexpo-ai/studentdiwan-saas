import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final childrenAsync = ref.watch(childrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);

    return Scaffold(
      body: SafeArea(
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => ErrorState(message: 'Failed to load data.\n$e'),
          data: (kids) {
            if (kids.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Children Linked',
                subtitle: 'Your account is not linked to any students. Contact the school admin.',
              );
            }

            final kid = selectedChild ?? kids.first;
            if (selectedChild == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedChildProvider.notifier).state = kids.first;
              });
            }

            return _HomeBody(user: user, kid: kid, kids: kids, greeting: _greeting());
          },
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final UserModel user;
  final StudentModel kid;
  final List<StudentModel> kids;
  final String greeting;

  const _HomeBody({required this.user, required this.kid, required this.kids, required this.greeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesProvider(kid.id));
    final attAsync = ref.watch(attendanceProvider(kid.id));
    final asgnAsync = ref.watch(assignmentsProvider(kid));
    final noticesAsync = ref.watch(noticesProvider);

    // Compute stats
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayAtt = attAsync.valueOrNull?.where((a) => DateFormat('yyyy-MM-dd').format(a.date) == today).firstOrNull;
    final monthAtt = attAsync.valueOrNull ?? [];
    final presentCount = monthAtt.where((a) => a.status == 'Present').length;
    final attPct = monthAtt.isNotEmpty ? (presentCount / monthAtt.length * 100).round() : 0;
    final pendingAsgn = asgnAsync.valueOrNull?.where((a) => !a.submitted).length ?? 0;
    final dueInvoices = feesAsync.valueOrNull?.where((inv) => !inv.isPaid).toList() ?? [];
    final totalDue = dueInvoices.fold(0.0, (s, inv) => s + inv.amount);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        clearCache();
        ref.invalidate(childrenProvider);
        ref.invalidate(feesProvider(kid.id));
        ref.invalidate(attendanceProvider(kid.id));
        ref.invalidate(assignmentsProvider(kid));
        ref.invalidate(noticesProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting, style: const TextStyle(fontSize: 14, color: AppColors.text2, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(user.displayName, style: context.heading1),
                  const SizedBox(height: 2),
                  const Text('Welcome to Student Diwan', style: TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500)),
                ])),
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.primaryGradient),
                    ),
                    child: Center(child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                  ),
                ),
              ]),
            ),
          ),

          // Child Card
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => context.push('/children'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF74B9FF), Color(0xFF0984E3)]),
                    ),
                    child: Center(child: Text(kid.initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(kid.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text1)),
                    const SizedBox(height: 3),
                    Text('${kid.gradeLabel}${kid.rollNumber.isNotEmpty ? ' · Roll No. ${kid.rollNumber}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500)),
                  ])),
                  if (kids.length > 1) const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.text3),
                ]),
              ),
            ),
          ),

          // Fee Banner
          if (dueInvoices.isNotEmpty)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push('/fees'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.red, Color(0xFFFF6B6B)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Outstanding Fee', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      Text(dueInvoices.first.dueDate != null
                        ? 'Due by ${DateFormat('d MMM yyyy').format(dueInvoices.first.dueDate!)}'
                        : 'Payment pending',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                    ]),
                    const Spacer(),
                    Text('BHD ${totalDue.toStringAsFixed(3)}',
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
            ),

          // Overview Stats
          SliverToBoxAdapter(child: SectionHeader(title: "Today's Overview", actionLabel: 'View All', onAction: () => context.push('/more'))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.4,
              ),
              delegate: SliverChildListDelegate([
                StatCard(
                  value: todayAtt?.status ?? '--',
                  label: "Today's Attendance",
                  sub: '$attPct% this month',
                  iconBg: AppColors.greenLight, iconColor: AppColors.green,
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () => context.push('/attendance'),
                ),
                StatCard(
                  value: pendingAsgn.toString(),
                  label: 'Pending Assignments',
                  sub: pendingAsgn > 0 ? '$pendingAsgn pending' : 'All done!',
                  iconBg: AppColors.primaryExtraLight, iconColor: AppColors.primary,
                  icon: Icons.edit_note_rounded,
                  onTap: () => context.push('/assignments'),
                ),
                StatCard(
                  value: dueInvoices.isEmpty ? 'Paid' : 'BHD ${totalDue.toStringAsFixed(3)}',
                  label: 'Fee Status',
                  sub: dueInvoices.isEmpty ? 'All clear' : '${dueInvoices.length} invoice(s)',
                  iconBg: dueInvoices.isEmpty ? AppColors.greenLight : AppColors.redLight,
                  iconColor: dueInvoices.isEmpty ? AppColors.green : AppColors.red,
                  icon: Icons.receipt_long_rounded,
                  onTap: () => context.push('/fees'),
                ),
                StatCard(
                  value: '$presentCount',
                  label: 'Days Present',
                  sub: 'This month',
                  iconBg: const Color(0xFFE8F4FD), iconColor: AppColors.blue,
                  icon: Icons.calendar_month_rounded,
                  onTap: () => context.push('/attendance'),
                ),
              ]),
            ),
          ),

          // Quick Access
          const SliverToBoxAdapter(child: SectionHeader(title: 'Quick Access')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _QuickItem(icon: Icons.check_circle_outline_rounded, label: 'Attendance', color: AppColors.green, bg: AppColors.greenLight, route: '/attendance'),
                _QuickItem(icon: Icons.edit_note_rounded, label: 'Assignments', color: AppColors.primary, bg: AppColors.primaryExtraLight, route: '/assignments', badge: pendingAsgn > 0 ? pendingAsgn.toString() : null),
                _QuickItem(icon: Icons.bar_chart_rounded, label: 'Gradebook', color: const Color(0xFF2E7D32), bg: const Color(0xFFE8F5E9), route: '/gradebook'),
                _QuickItem(icon: Icons.description_outlined, label: 'Report Cards', color: AppColors.primary, bg: AppColors.primaryExtraLight, route: '/report-cards'),
                _QuickItem(icon: Icons.mail_outline_rounded, label: 'Messages', color: const Color(0xFFC2185B), bg: const Color(0xFFFCE4EC), route: '/messages'),
                _QuickItem(icon: Icons.people_outline_rounded, label: 'PTM', color: AppColors.blue, bg: AppColors.blueLight, route: '/ptm'),
                _QuickItem(icon: Icons.directions_bus_outlined, label: 'Transport', color: AppColors.blue, bg: AppColors.blueLight, route: '/transport'),
                _QuickItem(icon: Icons.apps_rounded, label: 'More', color: const Color(0xFF7B1FA2), bg: const Color(0xFFF3E5F5), route: '/more'),
              ]),
            ),
          ),

          // Announcements
          SliverToBoxAdapter(
            child: SectionHeader(title: 'Announcements', actionLabel: 'All', onAction: () => context.push('/announcements')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: noticesAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                error: (_, __) => const SizedBox.shrink(),
                data: (notices) {
                  if (notices.isEmpty) return const SizedBox.shrink();
                  final colors = [AppColors.red, AppColors.amber, AppColors.green, AppColors.blue, AppColors.primary];
                  return Column(
                    children: notices.take(3).toList().asMap().entries.map((e) {
                      final n = e.value;
                      final c = colors[e.key % colors.length];
                      return _AnnouncementBanner(notice: n, color: c);
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _QuickItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final String route;
  final String? badge;

  const _QuickItem({required this.icon, required this.label, required this.color, required this.bg, required this.route, this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(route),
    child: Column(children: [
      Stack(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 24),
        ),
        if (badge != null) Positioned(
          top: -2, right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.background, width: 2)),
            child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text2), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _AnnouncementBanner extends StatelessWidget {
  final NoticeModel notice;
  final Color color;

  const _AnnouncementBanner({required this.notice, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: color, width: 4)),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10)],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4, right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(notice.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
        const SizedBox(height: 3),
        Text(notice.content, style: const TextStyle(fontSize: 11, color: AppColors.text3, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(
          notice.createdAt != null ? DateFormat('d MMM yyyy').format(notice.createdAt!) : '',
          style: const TextStyle(fontSize: 10, color: AppColors.text3),
        ),
      ])),
    ]),
  );
}

class _BottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _NavBtn(icon: Icons.home_rounded, label: 'Home', active: true, onTap: () {}),
            _NavBtn(icon: Icons.people_rounded, label: 'Children', onTap: () => context.push('/children')),
            _NavCenter(onTap: () => context.push('/fees')),
            _NavBtn(icon: Icons.calendar_month_rounded, label: 'Calendar', onTap: () => context.push('/calendar')),
            _NavBtn(icon: Icons.apps_rounded, label: 'More', onTap: () => context.push('/more')),
          ]),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (active) Container(width: 22, height: 3, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 2),
        Icon(icon, color: active ? AppColors.primary : AppColors.text3, size: 22),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.text3)),
      ]),
    ),
  );
}

class _NavCenter extends StatelessWidget {
  final VoidCallback onTap;
  const _NavCenter({required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: AppColors.primaryGradient),
            boxShadow: [BoxShadow(color: Color(0x801A56DB), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 24),
        ),
        const Text('Pay Fees', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ]),
    ),
  );
}
