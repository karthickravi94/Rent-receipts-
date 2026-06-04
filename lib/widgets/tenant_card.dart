import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tenant.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onGenerateReceipt;

  const TenantCard({
    super.key,
    required this.tenant,
    this.onEdit,
    this.onDelete,
    this.onGenerateReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    tenant.name.isNotEmpty
                        ? tenant.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(tenant.houseName,
                          style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                    if (v == 'receipt') onGenerateReceipt?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'receipt',
                        child: ListTile(
                            leading: Icon(Icons.receipt_long),
                            title: Text('Generate Receipt'))),
                    const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete',
                                style: TextStyle(color: Colors.red)))),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _chip(context, Icons.phone, tenant.phone),
                const SizedBox(width: 8),
                _chip(context, Icons.currency_rupee,
                    fmt.format(tenant.monthlyRent)),
              ],
            ),
            if (tenant.gpayNumber.isNotEmpty || tenant.phonePeNumber.isNotEmpty) ...
              [
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (tenant.gpayNumber.isNotEmpty)
                      _chip(context, Icons.payments, 'GPay: ${tenant.gpayNumber}'),
                    if (tenant.gpayNumber.isNotEmpty && tenant.phonePeNumber.isNotEmpty)
                      const SizedBox(width: 8),
                    if (tenant.phonePeNumber.isNotEmpty)
                      _chip(context, Icons.phone_android,
                          'PhonePe: ${tenant.phonePeNumber}'),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
