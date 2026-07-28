import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(studentFeesProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'School Fees & Invoices',
            subtitle: 'View outstanding balances and payment history',
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: feesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _empty(context, 'Could not load invoices right now.'),
              data: (invoices) => _buildBody(context, ref, invoices),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<FeeInvoice> invoices) {
    if (invoices.isEmpty) {
      return _empty(context, 'No invoices have been issued yet.');
    }

    final outstanding = invoices
        .where((i) => !i.isPaid)
        .fold<double>(0, (sum, i) => sum + i.amount);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentFeesProvider),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Outstanding Due',
                        style: TextStyle(color: AppColors.text3, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      money(outstanding),
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
                if (outstanding <= 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.greenLight, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Fully Paid',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green, fontSize: 13)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showPaymentSheet(context, ref, outstanding),
                    child: const Text('Pay All Due', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invoice History', style: context.heading2),
            ],
          ),
          const SizedBox(height: 12),
          ...invoices.map((invoice) {
            final statColor = invoice.isPaid ? AppColors.green : AppColors.red;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryExtraLight),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: statColor.withOpacity(0.08), shape: BoxShape.circle),
                    child: Icon(Icons.receipt_long_rounded, color: statColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice #${invoice.invoiceNumber}',
                            style: context.heading3.copyWith(fontSize: 14)),
                        if (invoice.dateDue.isNotEmpty)
                          Text('Due date: ${_fmtDate(invoice.dateDue)}', style: context.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(invoice.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text1)),
                      const SizedBox(height: 4),
                      if (invoice.isPaid)
                        TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                          onPressed: () => _showReceiptModal(context, invoice),
                          child: const Text('Receipt', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        )
                      else
                        StatusChip(
                          label: 'Unpaid',
                          textColor: statColor,
                          bgColor: statColor.withOpacity(0.08),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _empty(BuildContext context, String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.text3),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.text2, fontSize: 14)),
            ],
          ),
        ),
      );

  void _showPaymentSheet(BuildContext context, WidgetRef ref, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete Fee Payment', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Amount Due: ${money(amount)}', style: const TextStyle(color: AppColors.text2, fontSize: 14)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
              title: const Text('Credit / Debit Card'),
              subtitle: const Text('PayTabs / Visa / Mastercard'),
              onTap: () async {
                Navigator.pop(ctx);
                await payFeeInvoice(ref, invoiceNumber: 'ALL', amount: amount, paymentMethod: 'Card');
                ref.invalidate(studentFeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment processed successfully!'), backgroundColor: AppColors.green),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_rounded, color: AppColors.green),
              title: const Text('Bank Transfer'),
              subtitle: const Text('Direct portal wire transfer'),
              onTap: () async {
                Navigator.pop(ctx);
                await payFeeInvoice(ref, invoiceNumber: 'ALL', amount: amount, paymentMethod: 'Bank Transfer');
                ref.invalidate(studentFeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfer confirmation logged!'), backgroundColor: AppColors.green),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, FeeInvoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Official Fee Receipt', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #: ${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Amount Paid: ${money(invoice.amount)}'),
            const SizedBox(height: 6),
            Text('Status: Fully Paid (Verified)', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Receipt generated by Diwan ERP Financial Services.', style: TextStyle(fontSize: 11, color: AppColors.text3)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

