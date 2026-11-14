import 'package:flutter/material.dart';
import 'package:handyman_mart/core/theme/app_theme.dart';

enum BuildingType {
  house('House', 'Single or multi-family home', Icons.home_rounded),
  flat('Flat', 'Multi-unit residential building', Icons.apartment_rounded),
  office('Office', 'Workplace with entry restrictions', Icons.work_rounded),
  hotel('Hotel', 'Lodging, motel or resort', Icons.hotel_rounded),
  other('Other', 'Hospital, park, outdoors, etc', Icons.location_on_rounded);

  const BuildingType(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

/// "Choose your building" sheet matching the reference screenshot.
class ChooseBuildingSheet extends StatelessWidget {
  const ChooseBuildingSheet({super.key});

  static Future<BuildingType?> show(BuildContext context) {
    return showModalBottomSheet<BuildingType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChooseBuildingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, BuildingType.house),
                child: const Text('Skip', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your building',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Let us know your building type for more accurate deliveries.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          for (final type in BuildingType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.icon, color: AppColors.ink, size: 22),
                ),
                title: Text(type.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                subtitle: Text(type.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                onTap: () => Navigator.pop(context, type),
              ),
            ),
        ],
      ),
    );
  }
}
