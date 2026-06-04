import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/receipt_card.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  State<ReceiptHistoryScreen> createState() =>
      _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  String? _filterMonth;
  int? _filterYear;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final settings = context.read<SettingsProvider>();
    final now = DateTime.now();

    final filtered = provider.receipts.where((r) {
      if (_filterMonth != null && r.month != _filterMonth) return false;
      if (_filterYear != null && r.year != _filterYear) return false;
      if (_search.isNotEmpty &&
          !r.tenantName
              .toLowerCase()
              .contains(_search.toLowerCase()) &&
          !r.houseName
              .toLowerCase()
              .contains(_search.toLowerCase())) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search tenant or house...',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilter(context, now),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chips
          if (_filterMonth != null || _filterYear != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Filters: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_filterMonth != null)
                    Chip(
                      label: Text(_filterMonth!),
                      onDeleted: () =>
                          setState(() => _filterMonth = null),
                    ),
                  if (_filterYear != null) ...
                    [
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_filterYear.toString()),
                        onDeleted: () =>
                            setState(() => _filterYear = null),
                      ),
                    ],
                ],
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 72,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text('No receipts found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final receipt = filtered[i];
                      return ReceiptCard(
                        receipt: receipt,
                        onView: () async {
                          final pdf = await provider.regeneratePdf(
                            receipt,
                            settings.adminName,
                            settings.adminPhone,
                          );
                          if (pdf != null) {
                            // Open file
                          }
                        },
                        onShare: () async {
                          final pdf = await provider.regeneratePdf(
                            receipt,
                            settings.adminName,
                            settings.adminPhone,
                          );
                          if (pdf != null && context.mounted) {
                            provider.shareFile(pdf);
                          }
                        },
                        onDelete: () =>
                            _confirmDelete(context, receipt.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilter(
      BuildContext context, DateTime now) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Receipts',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Month',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.months
                    .map((m) => FilterChip(
                          label: Text(m),
                          selected: _filterMonth == m,
                          onSelected: (s) {
                            setModal(() => _filterMonth = s ? m : null);
                            setState(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Year',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(
                  3,
                  (i) {
                    final y = now.year - i;
                    return FilterChip(
                      label: Text(y.toString()),
                      selected: _filterYear == y,
                      onSelected: (s) {
                        setModal(() => _filterYear = s ? y : null);
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filterMonth = null;
                          _filterYear = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String receiptId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Receipt'),
        content:
            const Text('This receipt will be permanently deleted.'),
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
    if (ok == true && mounted) {
      context.read<ReceiptProvider>().deleteReceipt(receiptId);
    }
  }
}
