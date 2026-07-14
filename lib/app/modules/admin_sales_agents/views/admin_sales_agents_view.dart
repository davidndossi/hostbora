import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/admin_sales_agents_controller.dart';

class AdminSalesAgentsView extends BaseView<AdminSalesAgentsController> {
  AdminSalesAgentsView({super.key});

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t('Sales agents', 'Wakala wa mauzo'),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: _t('Search agents', 'Tafuta wakala'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => controller.searchQuery.value = v,
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingList.value && controller.agents.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = controller.filteredAgents;
            if (rows.isEmpty) {
              return Center(child: Text(_t('No agents yet', 'Hakuna wakala bado')));
            }
            return RefreshIndicator(
              onRefresh: controller.loadAgents,
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final agent = rows[index];
                  final active = agent.status.toLowerCase() == 'active';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(agent.fullName),
                      subtitle: Text('${agent.agentCode} · ${agent.phone}'),
                      trailing: Switch(
                        value: active,
                        onChanged: (_) => controller.toggleStatus(agent),
                      ),
                      onTap: () => controller.openAgentDashboard(agent),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget? floatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showCreateSheet(Get.context!),
      child: const Icon(Icons.person_add_outlined),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('Add sales agent', 'Ongeza wakala wa mauzo'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.fullNameController,
                decoration: InputDecoration(labelText: _t('Full name', 'Jina kamili')),
                validator: (v) => (v == null || v.trim().isEmpty) ? _t('Required', 'Lazima') : null,
              ),
              TextFormField(
                controller: controller.phoneController,
                decoration: InputDecoration(labelText: _t('Phone', 'Simu')),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: controller.emailController,
                decoration: InputDecoration(labelText: _t('Email', 'Barua pepe')),
              ),
              TextFormField(
                controller: controller.regionController,
                decoration: InputDecoration(labelText: _t('Region', 'Mkoa')),
              ),
              TextFormField(
                controller: controller.agentCodeController,
                decoration: InputDecoration(
                  labelText: _t('Agent code (optional)', 'Msimbo (si lazima)'),
                ),
              ),
              TextFormField(
                controller: controller.userIdController,
                decoration: InputDecoration(
                  labelText: _t('Host Bora user ID (optional)', 'Kitambulisho cha mtumiaji'),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSaving.value ? null : controller.createAgent,
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_t('Create agent', 'Unda wakala')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
