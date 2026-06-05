import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/receipt_provider.dart';
import '../utils/constants.dart';
import '../widgets/stat_card.dart';
import '../widgets/receipt_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, String receiptId, ReceiptProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text('This receipt will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      provider.deleteReceipt(receiptId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = context.watch<TenantProvider>();
    final receiptProvider = context.watch<ReceiptProvider>();
    final now = DateTime.now();
    final currentMonth = AppConstants.monthName(now.month);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final tenants = tenantProvider.tenants;
    final allReceipts = receiptProvider.receipts;
    final monthReceipts =
        receiptProvider.filtered(month: currentMonth, year: now.year);
    final totalRent =
        tenants.fold<double>(0, (sum, t) => sum + t.monthlyRent);
    final collectedThisMonth =
        monthReceipts.fold<double>(0, (sum, r) => sum + r.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Receipt Manager'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              radius: 18,
              child: Icon(
                Icons.home_work,
                color:
                    Theme.of(context).colorScheme.onPrimaryContainer,
                size: 18,
              ),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '$currentMonth ${now.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Tenants',
                  value: tenants.length.toString(),
                  icon: Icons.people,
                  color: Colors.indigo,
                ),
                StatCard(
                  title: 'Monthly Rent',
                  value: fmt.format(totalRent),
                  icon: Icons.currency_rupee,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Receipts This Month',
                  value: monthReceipts.length.toString(),
                  icon: Icons.receipt,
                  color: Colors.orange,
                ),
                StatCard(
                  title: 'Collected This Month',
                  value: fmt.format(collectedThisMonth),
                  icon: Icons.account_balance_wallet,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (allReceipts.isNotEmpty) ...[
              Text(
                'Recent Receipts',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...allReceipts.take(5).map(
                    (r) => ReceiptCard(
                      receipt: r,
                      onView: () {},
                      onShare: () {},
                      onDelete: () =>
                          _confirmDelete(context, r.id, receiptProvider),
                    ),
                  ),
            ],

            if (allReceipts.isEmpty && tenants.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data yet',
                        style:
                            Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by adding a tenant from the Tenants tab.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
