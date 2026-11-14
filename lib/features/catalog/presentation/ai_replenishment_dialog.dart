import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handyman_mart/core/router/routes.dart';
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/voice/voice_service.dart';
import 'package:handyman_mart/features/cart/application/cart_controller.dart';
import 'package:handyman_mart/features/cart/application/cart_store.dart';
import 'package:handyman_mart/features/catalog/data/ai_recommendations.dart';
import 'package:handyman_mart/features/catalog/data/product.dart';
import 'package:handyman_mart/features/stores/data/store_models.dart';

/// Modal Popup Dialog with Telugu Voice Announcement for AI Replenishment.
class AiReplenishmentDialog extends ConsumerStatefulWidget {
  const AiReplenishmentDialog({super.key, required this.suggestion});
  final AiReplenishmentSuggestion suggestion;

  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final suggestion = ref.read(aiReplenishmentSuggestionProvider);
    final alreadyShown = ref.read(aiDismissedProvider);
    if (suggestion == null || suggestion.items.isEmpty || alreadyShown) return;

    ref.read(aiDismissedProvider.notifier).state = true;

    // Speak Telugu Voice Announcement
    try {
      final speaker = ref.read(speakerProvider);
      await speaker.speak(
        'మీరు 3 రోజుల క్రితం ఆర్డర్ చేసిన నిత్యావసర వస్తువులు మళ్లీ కావాలా? ఒకే ట్యాప్‌తో ఆర్డర్ చేయండి.',
        'te-IN',
      );
    } catch (_) {}

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => AiReplenishmentDialog(suggestion: suggestion),
      );
    }
  }

  @override
  ConsumerState<AiReplenishmentDialog> createState() => _AiReplenishmentDialogState();
}

class _AiReplenishmentDialogState extends ConsumerState<AiReplenishmentDialog> {
  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.amberDeep, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🤖 AI Smart Re-Order Assistant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                'మీరు ${suggestion.daysAgo} రోజుల క్రితం ఈ వస్తువులను ఆర్డర్ చేశారు (Order #${suggestion.orderMartId}). ఇవి మళ్లీ కావాలా?',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Past Essential Items:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in suggestion.items.take(5))
                  Chip(
                    avatar: const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.amberDeep),
                    label: Text(item.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    backgroundColor: Colors.grey.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final storeRef = StoreRef(
                        suggestion.vendorId.isNotEmpty ? suggestion.vendorId : kMainStoreId,
                        suggestion.vendorId.isNotEmpty ? 'Vendor Store' : kMainStoreName,
                      );
                      ref.read(cartStoreProvider.notifier).set(storeRef);
                      final cart = ref.read(cartProvider.notifier);
                      for (final item in suggestion.items) {
                        cart.add(Product(
                          id: item.name,
                          name: item.name,
                          category: 'Grocery',
                          mrp: item.price,
                          discount: 0,
                          price: item.price,
                          stockLeft: 99,
                          limit: 0,
                          code: item.name,
                          units: '1 item',
                          imageFile: null,
                          raw: const {},
                        ));
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Re-ordered ${suggestion.items.length} essential items into cart!')),
                      );
                      context.pushNamed(Routes.cart);
                    },
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('1-Tap Re-Order All\n(ఒకే ట్యాప్‌తో ఆర్డర్)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not Today (ఈరోజు వద్దు)', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
