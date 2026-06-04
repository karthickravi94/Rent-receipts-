import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../widgets/tenant_card.dart';
import 'add_edit_tenant_screen.dart';
import 'generate_receipt_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenantProvider>();
    final filtered = provider.tenants
        .where((t) =>
            t.name.toLowerCase().contains(_search.toLowerCase()) ||
            t.houseName.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              hintText: 'Search by name or house...',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditTenantScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Tenant'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 72,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _search.isNotEmpty
                            ? 'No tenants found'
                            : 'No tenants yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_search.isEmpty) ...
                        [
                          const SizedBox(height: 8),
                          const Text(
                              'Tap the button below to add a tenant.'),
                        ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final tenant = filtered[i];
                    return TenantCard(
                      tenant: tenant,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditTenantScreen(tenant: tenant),
                        ),
                      ),
                      onDelete: () => _confirmDelete(context, tenant.id),
                      onGenerateReceipt: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GenerateReceiptScreen(preselectedTenant: tenant),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String tenantId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tenant'),
        content:
            const Text('Are you sure? This will not delete the receipts.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<TenantProvider>().deleteTenant(tenantId);
    }
  }
}
