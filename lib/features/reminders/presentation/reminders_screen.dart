import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handyman_mart/core/router/routes.dart';
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/utils/money.dart';
import 'package:handyman_mart/core/widgets/app_button.dart';
import 'package:handyman_mart/features/reminders/data/reminder_models.dart';
import 'package:handyman_mart/features/reminders/data/reminders_repository.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(autoOrderRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Auto-Orders'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.amberDeep,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(text: 'Offer Milestones'),
            Tab(text: 'Auto-Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OffersTab(),
          _AutoOrdersTab(remindersAsync: remindersAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.ink,
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final itemsController = TextEditingController();
    String frequency = 'Weekly';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Schedule Auto-Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Reminder Title', hintText: 'e.g. Milk & Eggs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: itemsController,
              decoration: const InputDecoration(labelText: 'Items (comma separated)', hintText: 'e.g. Toned Milk, Eggs'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'Every 15 Days', child: Text('Every 15 Days')),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
              ],
              onChanged: (v) {
                if (v != null) frequency = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.ink),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final items = itemsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final newReminder = AutoOrderReminder(
                id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
                title: title,
                itemNames: items.isEmpty ? [title] : items,
                frequency: frequency,
                nextDueDate: DateTime.now().add(const Duration(days: 7)),
                isEnabled: true,
                offerTitle: '⚡ Auto-Replenishment Active',
                discountAmount: 20,
              );
              ref.read(autoOrderRemindersProvider.notifier).addReminder(newReminder);
              Navigator.pop(ctx);
            },
            child: const Text('Save Reminder'),
          ),
        ],
      ),
    );
  }
}

class _OffersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Active Offers & Cashback Reminders',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final offer in RemindersRepository.kOffers)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        offer.badgeText,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amberDeep),
                      ),
                    ),
                    Text(
                      rupees(offer.benefitAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16864A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(offer.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(offer.subtitle, style: text.bodySmall?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Order Now & Claim Benefit',
                    onPressed: () => context.goNamed(Routes.home),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AutoOrdersTab extends ConsumerWidget {
  const _AutoOrdersTab({required this.remindersAsync});
  final AsyncValue<List<AutoOrderReminder>> remindersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return remindersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amberDeep)),
      error: (e, _) => Center(child: Text('Error loading reminders: $e')),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alarm_off_rounded, size: 48, color: AppColors.muted),
                const SizedBox(height: 12),
                Text('No auto-orders scheduled', style: text.titleMedium),
                const SizedBox(height: 4),
                Text('Tap + to set up a recurring replenishment reminder.', style: text.bodySmall?.copyWith(color: AppColors.muted)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Scheduled Replenishment Reminders',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final r in list)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: r.isEnabled ? AppColors.amber : Theme.of(context).colorScheme.outlineVariant,
                    width: r.isEnabled ? 2 : 1,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: r.isEnabled ? AppColors.amber : Colors.grey.shade300,
                          child: Icon(Icons.autorenew_rounded, color: r.isEnabled ? AppColors.ink : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              Text('Frequency: ${r.frequency}', style: text.bodySmall?.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: r.isEnabled,
                          activeColor: AppColors.amberDeep,
                          onChanged: (_) => ref.read(autoOrderRemindersProvider.notifier).toggleReminder(r.id),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('Items:', style: text.labelSmall?.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final item in r.itemNames)
                          Chip(
                            label: Text(item, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.grey.shade100,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.offerTitle,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amberDeep),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: AppColors.ink,
                          ),
                          onPressed: () => context.goNamed(Routes.home),
                          icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                          label: const Text('Re-order Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
