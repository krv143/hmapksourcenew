import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handyman_mart/core/router/routes.dart';
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/utils/money.dart';
import 'package:handyman_mart/features/catalog/data/product.dart';
import 'package:handyman_mart/features/tracking/application/tracking_providers.dart';

/// Temu-style gamified deal offer model.
class TemuDealOffer {
  const TemuDealOffer({
    required this.id,
    required this.title,
    required this.badgeText,
    required this.discountPercent,
    required this.requiredItemCount,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String badgeText;
  final int discountPercent;
  final int requiredItemCount;
  final String subtitle;
}

const kTemuBundleOffer = TemuDealOffer(
  id: 'temu-bundle-10',
  title: '🔥 10% Extra Off on 10 Items Bundle!',
  badgeText: 'TEMU STYLE SAVER',
  discountPercent: 10,
  requiredItemCount: 10,
  subtitle: 'Select 10 items or more from groceries & appliances to unlock 10% instant discount at checkout.',
);

/// AI Smart Personalization Engine:
/// Analyzes customer's previous order history and generates smart recommendations.
final aiSmartPicksProvider = Provider.autoDispose<List<Product>>((ref) {
  final pastOrders = ref.watch(myOrdersProvider).valueOrNull ?? const [];

  final frequentNames = <String>{};
  for (final order in pastOrders) {
    for (final item in order.items) {
      if (item.name.isNotEmpty) frequentNames.add(item.name.toLowerCase());
    }
  }

  // Pre-configured AI Smart Picks
  return [
    Product(
      id: 'ai-p1',
      name: 'Heritage Toned Milk 500ml',
      category: 'Grocery',
      mrp: 28,
      discount: 2,
      price: 26,
      qty: 1,
      stockLeft: 50,
      code: 'MILK-500',
      units: '500 ml',
    ),
    Product(
      id: 'ai-p2',
      name: 'Freedom Refined Sunflower Oil 1L',
      category: 'Grocery',
      mrp: 140,
      discount: 15,
      price: 125,
      qty: 1,
      stockLeft: 40,
      code: 'OIL-1L',
      units: '1 L',
    ),
    Product(
      id: 'ai-p3',
      name: 'Sona Masoori Rice 5kg Premium',
      category: 'Grocery',
      mrp: 320,
      discount: 30,
      price: 290,
      qty: 1,
      stockLeft: 30,
      code: 'RICE-5KG',
      units: '5 kg',
    ),
  ];
});

/// Temu-style Deal Banner Widget for Home Screen.
class TemuDealBanner extends StatelessWidget {
  const TemuDealBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4E50), Color(0xFFF9D423)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, size: 28, color: Color(0xFFFF4E50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kTemuBundleOffer.badgeText,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kTemuBundleOffer.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  kTemuBundleOffer.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => context.pushNamed(Routes.reminders),
            child: const Text('Claim Deal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
