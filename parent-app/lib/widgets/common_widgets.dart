import 'package:flutter/material.dart';
import '../core/theme.dart';

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Row(children: [
      Text(title.toUpperCase(), style: context.label),
      const Spacer(),
      if (trailing != null) trailing!
      else if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
    ]),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? sub;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.sub,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.text1, height: 1)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600)),
        if (sub != null) ...[
          const SizedBox(height: 5),
          Text(sub!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.green)),
        ],
      ]),
    ),
  );
}

// ── Loading Shimmer ───────────────────────────────────────────────────────────
class LoadingCard extends StatelessWidget {
  final double height;
  const LoadingCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

// ── Empty State ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 34, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.text3), textAlign: TextAlign.center),
        ],
      ]),
    ),
  );
}

// ── Error State ───────────────────────────────────────────────────────────────
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.text3),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(fontSize: 13, color: AppColors.text2), textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ]),
    ),
  );
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg, fg;
    if (s == 'paid') { bg = AppColors.greenLight; fg = AppColors.green; }
    else if (s == 'overdue' || s == 'absent') { bg = AppColors.redLight; fg = AppColors.red; }
    else if (s == 'late' || s == 'pending' || s == 'partial') { bg = AppColors.amberLight; fg = AppColors.amber; }
    else if (s == 'present') { bg = AppColors.greenLight; fg = AppColors.green; }
    else { bg = AppColors.primaryExtraLight; fg = AppColors.primary; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const InfoRow({super.key, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.primarySurface, width: 1)),
    ),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
    ]),
  );
}

// ── App Back Header ───────────────────────────────────────────────────────────
class AppBackHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppBackHeader({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: AppColors.background,
    leading: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)],
        ),
        child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.text1),
      ),
    ),
    title: Text(title),
    actions: actions,
  );
}

// ── Gradient Card ─────────────────────────────────────────────────────────────
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsets padding;

  const GradientCard({
    super.key,
    required this.child,
    this.colors = AppColors.cardGradient,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

// ── White Card ────────────────────────────────────────────────────────────────
class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const WhiteCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: child,
    ),
  );
}
