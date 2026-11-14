import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:handyman_mart/features/reminders/data/reminder_models.dart';

class RemindersRepository {
  static const _kStorageKey = 'hm_auto_order_reminders';

  static final List<AutoOrderReminder> kDefaultReminders = [
    AutoOrderReminder(
      id: 'rem-1',
      title: 'Fresh Milk & Dairy Supplies',
      itemNames: const ['Heritage Toned Milk 500ml', 'Fresh Curd 500g'],
      frequency: 'Daily',
      nextDueDate: DateTime.now().add(const Duration(days: 1)),
      isEnabled: true,
      offerTitle: '5% Subscription Discount',
      discountAmount: 10,
    ),
    AutoOrderReminder(
      id: 'rem-2',
      title: 'Weekly Grocery Replenishment',
      itemNames: const ['Sona Masoori Rice 5kg', 'Sunflower Cooking Oil 1L', 'Toor Dal 1kg'],
      frequency: 'Weekly',
      nextDueDate: DateTime.now().add(const Duration(days: 4)),
      isEnabled: true,
      offerTitle: '₹50 Basket Discount',
      discountAmount: 50,
    ),
    AutoOrderReminder(
      id: 'rem-3',
      title: 'Monthly Household Essentials',
      itemNames: const ['Detergent Powder 2kg', 'Dishwash Liquid 500ml', 'Floor Cleaner 1L'],
      frequency: 'Monthly',
      nextDueDate: DateTime.now().add(const Duration(days: 12)),
      isEnabled: true,
      offerTitle: '₹100 Cashback Milestone',
      discountAmount: 100,
    ),
  ];

  static const List<CustomerOfferMilestone> kOffers = [
    CustomerOfferMilestone(
      id: 'off-1',
      title: '₹50 Welcome Wallet Balance',
      subtitle: 'Automatically credited to your wallet for first orders above ₹150.',
      badgeText: 'WELCOME OFFER',
      isClaimed: true,
      benefitAmount: 50,
    ),
    CustomerOfferMilestone(
      id: 'off-2',
      title: '₹20 Extra Cashback on Orders > ₹300',
      subtitle: 'Earn ₹20 wallet cashback on every order above ₹300.',
      badgeText: 'CASHBACK MILESTONE',
      isClaimed: false,
      benefitAmount: 20,
    ),
    CustomerOfferMilestone(
      id: 'off-3',
      title: 'Free Delivery on Orders > ₹199',
      subtitle: 'Enjoy 100% free home delivery on all grocery and appliance orders.',
      badgeText: 'FREE DELIVERY',
      isClaimed: false,
      benefitAmount: 30,
    ),
  ];

  Future<List<AutoOrderReminder>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return [for (final item in decoded) if (item is Map) AutoOrderReminder.fromJson(Map<String, dynamic>.from(item))];
        }
      }
    } catch (_) {}
    return kDefaultReminders;
  }

  Future<void> saveReminders(List<AutoOrderReminder> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = [for (final r in list) r.toJson()];
      await prefs.setString(_kStorageKey, jsonEncode(jsonList));
    } catch (_) {}
  }
}

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) => RemindersRepository());

class AutoOrderRemindersNotifier extends StateNotifier<AsyncValue<List<AutoOrderReminder>>> {
  AutoOrderRemindersNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  final RemindersRepository _repo;

  Future<void> _init() async {
    try {
      final list = await _repo.loadReminders();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleReminder(String id) async {
    final current = state.valueOrNull ?? [];
    final updated = [
      for (final r in current)
        if (r.id == id) r.copyWith(isEnabled: !r.isEnabled) else r,
    ];
    state = AsyncValue.data(updated);
    await _repo.saveReminders(updated);
  }

  Future<void> addReminder(AutoOrderReminder reminder) async {
    final current = state.valueOrNull ?? [];
    final updated = [...current, reminder];
    state = AsyncValue.data(updated);
    await _repo.saveReminders(updated);
  }
}

final autoOrderRemindersProvider =
    StateNotifierProvider<AutoOrderRemindersNotifier, AsyncValue<List<AutoOrderReminder>>>(
  (ref) => AutoOrderRemindersNotifier(ref.watch(remindersRepositoryProvider)),
);
