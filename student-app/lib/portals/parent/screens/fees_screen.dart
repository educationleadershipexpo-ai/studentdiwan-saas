import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart' show ParentBottomNav, ParentSideDrawer;

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedChildProvider);
    if (kid == null) return const Scaffold(body: Center(child: Text('No child selected')));

    final feesAsync = ref.watch(feesProvider(kid.id));

    return Scaffold(
      backgroundColor: context.bgColor,
      drawer: const ParentSideDrawer(),
      appBar: const AppBackHeader(title: 'Fees & Payments'),
      bottomNavigationBar: const ParentBottomNav(activeRoute: '/parent/fees'),
      body: feesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: 'Failed to load fees', onRetry: () => ref.invalidate(feesProvider(kid.id))),
        data: (invoices) {
          final due = invoices.where((i) => !i.isPaid).toList();
          final paid = invoices.where((i) => i.isPaid).toList();
          final totalDue = due.fold(0.0, (s, i) => s + i.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Total card
              GradientCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TOTAL OUTSTANDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text('BHD ${totalDue.toStringAsFixed(3)}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  Text('${kid.firstName} ${kid.lastName} · ${due.length} pending invoice(s)',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 16),
                  if (due.isNotEmpty) SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _startPayment(
                        context, ref,
                        amount: totalDue,
                        orderId: due.first.id,
                        description: 'School fees — ${kid.fullName} (${due.length} invoice(s))',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text('Pay Now — BHD ${totalDue.toStringAsFixed(3)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              if (due.isNotEmpty) ...[
                const SectionHeader(title: 'Pending Fees'),
                ...due.map((inv) => _FeeItem(
                      invoice: inv,
                      onPay: () => _startPayment(
                        context, ref,
                        amount: inv.amount,
                        orderId: inv.id,
                        description: '${inv.description} — ${kid.fullName}',
                      ),
                    )),
              ],

              if (paid.isNotEmpty) ...[
                const SectionHeader(title: 'Payment History'),
                ...paid.map((inv) => _FeeItem(invoice: inv)),
              ],

              if (invoices.isEmpty) const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No Invoices Found',
                subtitle: 'No fee records are available for this student.',
              ),
            ]),
          );
        },
      ),
    );
  }

  // Real payment flow. Checks whether the PayTabs gateway is actually
  // configured; if so, creates a hosted-checkout session and opens the real
  // redirect URL. If not, tells the parent honestly that online payment isn't
  // available yet — never a fake "success".
  Future<void> _startPayment(
    BuildContext context,
    WidgetRef ref, {
    required double amount,
    required String orderId,
    required String description,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(authProvider).user;

    // Loading dialog while we talk to the gateway.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final configured = await ApiClient.instance.isPaymentGatewayConfigured();
      if (!configured) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showGatewayUnavailable(context);
        }
        return;
      }

      final url = await ApiClient.instance.createPaymentSession(
        amount: amount,
        currency: AppConstants.currency,
        description: description,
        orderId: orderId,
        // After checkout PayTabs redirects here; the app deep-links back to fees.
        returnUrl: '${AppConstants.baseUrl}/parent/fees',
        customerName: user?.displayName,
        customerEmail: user?.email,
      );

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(const SnackBar(content: Text('Could not open the payment page.')));
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Payment could not be started. ${_errorText(e)}')),
      );
    }
  }

  String _errorText(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
    }
    return 'Please try again later.';
  }

  void _showGatewayUnavailable(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Online Payment Unavailable', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Online payment is not enabled for your school yet. Please pay at the '
          'school office, or contact the office for payment options.',
          style: TextStyle(fontSize: 13, color: AppColors.text2, height: 1.5),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got It')),
        ],
      ),
    );
  }
}

class _FeeItem extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onPay;
  const _FeeItem({required this.invoice, this.onPay});

  @override
  Widget build(BuildContext context) {
    final status = invoice.isPaid ? 'Paid' : invoice.isOverdue ? 'Overdue' : 'Pending';
    return WhiteCard(
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: invoice.isPaid ? AppColors.greenLight : AppColors.redLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            invoice.isPaid ? Icons.check_circle_outline_rounded : Icons.receipt_outlined,
            color: invoice.isPaid ? AppColors.green : AppColors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(invoice.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
          const SizedBox(height: 2),
          Text(
            invoice.isPaid && invoice.paidDate != null
              ? 'Paid: ${DateFormat('d MMM yyyy').format(invoice.paidDate!)}'
              : invoice.dueDate != null ? 'Due: ${DateFormat('d MMM yyyy').format(invoice.dueDate!)}' : '',
            style: const TextStyle(fontSize: 11, color: AppColors.text3),
          ),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('BHD ${invoice.amount.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.text1)),
          const SizedBox(height: 4),
          StatusBadge(status: status),
        ]),
        if (onPay != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('Pay', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }
}
