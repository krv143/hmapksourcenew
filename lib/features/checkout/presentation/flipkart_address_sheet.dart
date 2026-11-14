import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handyman_mart/core/router/routes.dart';
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/widgets/app_button.dart';
import 'package:handyman_mart/features/address/application/address_providers.dart';
import 'package:handyman_mart/features/address/data/address_models.dart';
import 'package:handyman_mart/features/address/data/address_repository.dart';
import 'package:handyman_mart/features/auth/application/session_controller.dart';
import 'package:handyman_mart/features/profile/application/profile_controller.dart';
import 'package:handyman_mart/features/stores/application/stores_providers.dart';

/// Flipkart-style Address Selection Modal Sheet.
class FlipkartAddressSheet extends ConsumerStatefulWidget {
  const FlipkartAddressSheet({super.key, required this.currentAddress});
  final AddressRecord currentAddress;

  static Future<AddressRecord?> show(BuildContext context, AddressRecord currentAddress) {
    return showModalBottomSheet<AddressRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FlipkartAddressSheet(currentAddress: currentAddress),
    );
  }

  @override
  ConsumerState<FlipkartAddressSheet> createState() => _FlipkartAddressSheetState();
}

class _FlipkartAddressSheetState extends ConsumerState<FlipkartAddressSheet> {
  late String _selectedRecordId;

  @override
  void initState() {
    super.initState();
    _selectedRecordId = widget.currentAddress.recordId.isNotEmpty ? widget.currentAddress.recordId : 'primary';
  }

  @override
  Widget build(BuildContext context) {
    final savedAddr = ref.watch(myAddressProvider).valueOrNull ?? widget.currentAddress;
    final profile = ref.watch(profileProvider).valueOrNull?.profile;

    final addresses = <AddressRecord>[
      if (savedAddr.address.isNotEmpty) savedAddr,
      if (profile != null && profile.addressLine.isNotEmpty && profile.addressLine != savedAddr.address)
        AddressRecord(
          recordId: 'prof-1',
          fullName: profile.fullName,
          mobileNumber: profile.mobileNumber,
          address: profile.addressLine,
          district: profile.district,
          zipCode: profile.zipCode,
        ),
      const AddressRecord(
        recordId: 'sample-1',
        fullName: 'Home Address',
        mobileNumber: '6281198953',
        address: 'Haritha Testing, Yendada, Visakhapatnam',
        district: 'Visakhapatnam',
        zipCode: '530045',
      ),
      const AddressRecord(
        recordId: 'sample-2',
        fullName: 'Work Office Address',
        mobileNumber: '6281198953',
        address: 'Nowroji Road, Maharani Peta, Siripuram, Visakhapatnam',
        district: 'Visakhapatnam',
        zipCode: '530003',
      ),
    ];

    final selected = addresses.firstWhere(
      (a) => a.recordId == _selectedRecordId,
      orElse: () => addresses.first,
    );

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.amberDeep, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Select Delivery Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Flipkart style "+ Add New Address" Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                side: const BorderSide(color: AppColors.amberDeep, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await context.pushNamed(Routes.address);
                ref.invalidate(myAddressProvider);
                ref.invalidate(profileProvider);
                ref.invalidate(storesProvider);
                ref.invalidate(selectedStoreIdProvider);
                ref.invalidate(selectedStoreProvider);
              },
              icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.amberDeep),
              label: const Text(
                '+ Add New Address',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.amberDeep),
              ),
            ),
          ),

          // Saved Addresses Radio List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: addresses.length,
              itemBuilder: (context, i) {
                final a = addresses[i];
                final isSelected = a.recordId == _selectedRecordId || (i == 0 && _selectedRecordId == 'primary');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF8E1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.amberDeep : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: a.recordId.isNotEmpty ? a.recordId : 'primary',
                    groupValue: _selectedRecordId,
                    activeColor: AppColors.amberDeep,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRecordId = val);
                    },
                    title: Row(
                      children: [
                        Text(
                          a.fullName.isEmpty ? 'Customer' : a.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a.zipCode.isEmpty ? '530016' : a.zipCode,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.amberDeep),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${a.address}, ${a.district.isEmpty ? 'Visakhapatnam' : a.district}\nPh: ${a.mobileNumber.isEmpty ? '6281198953' : a.mobileNumber}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Button: Deliver Here & Proceed to Pay
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
            ),
            child: AppButton(
              label: 'Deliver Here & Proceed to Pay',
              onPressed: () async {
                final session = ref.read(sessionProvider).valueOrNull;
                final userId = session?.userId ?? '';

                await ref.read(addressRepositoryProvider).save(
                      userId: userId,
                      existing: selected,
                      fullName: selected.fullName,
                      mobileNumber: selected.mobileNumber,
                      address: selected.address,
                      state: const MasterItem('1', 'Andhra Pradesh'),
                      district: MasterItem('104', selected.district.isEmpty ? 'Visakhapatnam' : selected.district),
                      zipCode: selected.zipCode.isEmpty ? '530016' : selected.zipCode,
                    );

                ref.invalidate(myAddressProvider);
                ref.invalidate(profileProvider);
                ref.invalidate(storesProvider);
                ref.invalidate(selectedStoreIdProvider);
                ref.invalidate(selectedStoreProvider);

                if (mounted) Navigator.pop(context, selected);
              },
            ),
          ),
        ],
      ),
    );
  }
}
