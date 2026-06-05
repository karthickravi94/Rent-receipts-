import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt.dart';
import '../models/tenant.dart';
import '../providers/tenant_provider.dart';
import '../providers/receipt_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';

class GenerateReceiptScreen extends StatefulWidget {
  final Tenant? preselectedTenant;
  const GenerateReceiptScreen({super.key, this.preselectedTenant});

  @override
  State<GenerateReceiptScreen> createState() =>
      _GenerateReceiptScreenState();
}

class _GenerateReceiptScreenState extends State<GenerateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  Tenant? _selectedTenant;
  late String _selectedMonth;
  late int _selectedYear;
  bool _generated = false;

  final _milk = TextEditingController();
  final _electricity = TextEditingController();
  final _water = TextEditingController();
  final _other = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = AppConstants.monthName(now.month);
    _selectedYear = now.year;
    if (widget.preselectedTenant != null) {
      _selectedTenant = widget.preselectedTenant;
    }
  }

  @override
  void dispose() {
    for (final c in [_milk, _electricity, _water, _other, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total =>
      (_selectedTenant?.monthlyRent ?? 0) +
      (double.tryParse(_milk.text) ?? 0) +
      (double.tryParse(_electricity.text) ?? 0) +
      (double.tryParse(_water.text) ?? 0) +
      (double.tryParse(_other.text) ?? 0);

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tenant.')),
      );
      return;
    }
    if (_generated) return;

    setState(() => _generated = true);

    final settings = context.read<SettingsProvider>();
    final receiptProvider = context.read<ReceiptProvider>();

    final bytes = await receiptProvider.generateAndSave(
      tenant: _selectedTenant!,
      milkCharge: double.tryParse(_milk.text) ?? 0,
      electricityCharge: double.tryParse(_electricity.text) ?? 0,
      waterCharge: double.tryParse(_water.text) ?? 0,
      otherCharges: double.tryParse(_other.text) ?? 0,
      notes: _notes.text.trim(),
      month: _selectedMonth,
      year: _selectedYear,
      adminName: settings.adminName,
      adminPhone: settings.adminPhone,
      receiptId: const Uuid().v4(),
    );

    if (bytes != null && mounted) {
      final receipt = receiptProvider.lastReceipt!;
      _showSuccessSheet(bytes, receipt);
    } else if (mounted) {
      setState(() => _generated = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                receiptProvider.error ?? 'Failed to generate receipt.')),
      );
    }
  }

  void _showSuccessSheet(Uint8List bytes, Receipt receipt) {
    final receiptProvider = context.read<ReceiptProvider>();
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            Text('Receipt Generated!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${receipt.tenantName} – ${receipt.month} ${receipt.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              fmt.format(receipt.totalAmount),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),

            // Download / Print PDF
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    receiptProvider.downloadOrShare(bytes),
                icon: const Icon(Icons.download),
                label: const Text('Download / Print PDF'),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: receipt.tenantEmail.isNotEmpty
                        ? () {
                            Navigator.pop(ctx);
                            receiptProvider.shareViaEmail(
                                receipt, receipt.tenantEmail);
                          }
                        : null,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      receiptProvider.openWhatsApp(
                          receipt.tenantPhone, receipt);
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _generated = false);
              },
              child: const Text('Generate Another Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenants = context.watch<TenantProvider>().tenants;
    final isGenerating =
        context.watch<ReceiptProvider>().isGenerating;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Receipt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tenant
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Select Tenant'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Tenant>(
                      value: _selectedTenant,
                      decoration: const InputDecoration(
                        labelText: 'Tenant *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: tenants
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t.name} – ${t.houseName}')))
                          .toList(),
                      onChanged: (t) =>
                          setState(() => _selectedTenant = t),
                      validator: (v) =>
                          v == null ? 'Please select a tenant' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Period
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Billing Period'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedMonth,
                            decoration:
                                const InputDecoration(labelText: 'Month'),
                            items: AppConstants.months
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(m)))
                                .toList(),
                            onChanged: (m) =>
                                setState(() => _selectedMonth = m!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration:
                                const InputDecoration(labelText: 'Year'),
                            items: List.generate(
                              5,
                              (i) => DropdownMenuItem(
                                value: now.year - 1 + i,
                                child: Text(
                                    (now.year - 1 + i).toString()),
                              ),
                            ),
                            onChanged: (y) =>
                                setState(() => _selectedYear = y!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Charges
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Charges'),
                    const SizedBox(height: 12),
                    if (_selectedTenant != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Base Rent'),
                            Text(
                              fmt.format(
                                  _selectedTenant!.monthlyRent),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(
                      label: 'Milk Charge (₹)',
                      controller: _milk,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.local_drink),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'\d+\.?\d*'))
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Electricity Charge (₹)',
                      controller: _electricity,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.electric_bolt),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'\d+\.?\d*'))
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Water Charge (₹)',
                      controller: _water,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.water_drop),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'\d+\.?\d*'))
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Other Charges (₹)',
                      controller: _other,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon:
                          const Icon(Icons.miscellaneous_services),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'\d+\.?\d*'))
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Notes',
                      controller: _notes,
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.note),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                          Text(fmt.format(_total),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: (isGenerating || _generated) ? null : _generate,
              icon: isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                  isGenerating ? 'Generating...' : 'Generate Receipt'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}
