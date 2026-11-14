import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/utils/money.dart';
import 'package:handyman_mart/features/cart/application/cart_controller.dart';
import 'package:handyman_mart/features/cart/data/cart_models.dart';

/// Dynamic Basket Cashback & Free Delivery Progress Bar.
class SmartBasketProgressBar extends ConsumerWidget {
  const SmartBasketProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(cartTotalsProvider);
    final totalSpent = totals.subtotal;

    final targetAmount = CartTotals.freeDeliveryFrom; // ₹199
    final needed = targetAmount - totalSpent;
    final progress = (totalSpent / targetAmount).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF198754)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  needed > 0
                      ? 'Add ${rupees(needed)} more to get FREE Delivery + ₹20 Cashback!'
                      : '🎉 CONGRATS! You unlocked FREE Delivery + ₹20 Cashback!',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F5132)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF198754),
            ),
          ),
        ],
      ),
    );
  }
}
