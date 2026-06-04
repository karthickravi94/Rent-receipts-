import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/tenant.dart';
import '../providers/tenant_provider.dart';
import '../widgets/custom_text_field.dart';

class AddEditTenantScreen extends StatefulWidget {
  final Tenant? tenant;
  const AddEditTenantScreen({super.key, this.tenant});

  @override
  State<AddEditTenantScreen> createState() => _AddEditTenantScreenState();
}

class _AddEditTenantScreenState extends State<AddEditTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  late final _email = TextEditingController();
  late final _house = TextEditingController();
  late final _rent = TextEditingController();
  late final _advance = TextEditingController();
  late final _gpay = TextEditingController();
  late final _phonePe = TextEditingController();

  bool get _isEditing => widget.tenant != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.tenant!;
      _name.text = t.name;
      _phone.text = t.phone;
      _email.text = t.email;
      _house.text = t.houseName;
      _rent.text = t.monthlyRent.toStringAsFixed(0);
      _advance.text = t.advanceAmount.toStringAsFixed(0);
      _gpay.text = t.gpayNumber;
      _phonePe.text = t.phonePeNumber;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _email, _house, _rent, _advance, _gpay, _phonePe
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tenant = Tenant(
      id: _isEditing ? widget.tenant!.id : const Uuid().v4(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      houseName: _house.text.trim(),
      monthlyRent: double.tryParse(_rent.text) ?? 0,
      advanceAmount: double.tryParse(_advance.text) ?? 0,
      gpayNumber: _gpay.text.trim(),
      phonePeNumber: _phonePe.text.trim(),
      createdAt:
          _isEditing ? widget.tenant!.createdAt : DateTime.now(),
    );

    final provider = context.read<TenantProvider>();
    final ok = _isEditing
        ? await provider.updateTenant(tenant)
        : await provider.addTenant(tenant);

    if (ok && mounted) Navigator.pop(context);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(provider.error ?? 'Failed to save tenant.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TenantProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tenant' : 'Add Tenant'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Tenant Information'),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Tenant Name',
              controller: _name,
              required: true,
              prefixIcon: const Icon(Icons.person),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Phone Number',
              controller: _phone,
              required: true,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: 20),
            _section('Property Details'),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'House Name / Property',
              controller: _house,
              required: true,
              prefixIcon: const Icon(Icons.home),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Monthly Rent (₹)',
              controller: _rent,
              required: true,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              prefixIcon: const Icon(Icons.currency_rupee),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*'))
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Advance / Security Deposit (₹)',
              controller: _advance,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              prefixIcon: const Icon(Icons.savings),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d*'))
              ],
            ),
            const SizedBox(height: 20),
            _section('Payment Details'),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'GPay Number',
              controller: _gpay,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.payments),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'PhonePe Number',
              controller: _phonePe,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_android),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _save,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Update Tenant' : 'Save Tenant'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}
