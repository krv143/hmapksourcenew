import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/widgets/app_button.dart';
import 'package:handyman_mart/features/address/application/address_providers.dart';
import 'package:handyman_mart/features/address/data/address_models.dart';
import 'package:handyman_mart/features/address/data/address_repository.dart';
import 'package:handyman_mart/features/address/presentation/choose_building_sheet.dart';
import 'package:handyman_mart/features/auth/application/session_controller.dart';
import 'package:handyman_mart/features/profile/application/profile_controller.dart';

/// "Address details" form with top mini-map preview matching reference screenshot.
class AddressDetailsScreen extends ConsumerStatefulWidget {
  const AddressDetailsScreen({
    super.key,
    required this.selectedPin,
    required this.addressText,
    this.initialBuildingType = BuildingType.flat,
  });

  final ll.LatLng selectedPin;
  final String addressText;
  final BuildingType initialBuildingType;

  @override
  ConsumerState<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends ConsumerState<AddressDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buildingNameController = TextEditingController();
  final _suiteFloorController = TextEditingController();
  late BuildingType _selectedBuildingType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedBuildingType = widget.initialBuildingType;
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _suiteFloorController.dispose();
    super.dispose();
  }

  Future<void> _saveAddressDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final session = ref.read(sessionProvider).valueOrNull;
      final userId = session?.userId ?? '';
      final building = _buildingNameController.text.trim();
      final suite = _suiteFloorController.text.trim();

      final fullFormattedAddress = [
        if (building.isNotEmpty) building,
        if (suite.isNotEmpty) 'Suite/Floor: $suite',
        widget.addressText,
        'Pin: ${widget.selectedPin.latitude.toStringAsFixed(5)}, ${widget.selectedPin.longitude.toStringAsFixed(5)}',
      ].join(', ');

      await ref.read(addressRepositoryProvider).save(
            userId: userId,
            existing: const AddressRecord(),
            fullName: session?.name ?? 'Customer',
            mobileNumber: session?.mobile ?? '',
            address: fullFormattedAddress,
            state: const MasterItem('1', 'Andhra Pradesh'),
            district: const MasterItem('104', 'Visakhapatnam'),
            zipCode: '530016',
          );

      ref.invalidate(myAddressProvider);
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address details saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address details. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address details'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top Mini-Map Preview
            SizedBox(
              height: 180,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.selectedPin,
                  initialZoom: 16.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.handyman.mart',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.selectedPin,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.black,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.addressText.isEmpty ? 'Visakhapatnam, Andhra Pradesh, India' : widget.addressText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 16),
                  const Text('Building type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<BuildingType>(
                    value: _selectedBuildingType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [
                      for (final b in BuildingType.values)
                        DropdownMenuItem(
                          value: b,
                          child: Text(b.title),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedBuildingType = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Business name / Building (required)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _buildingNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Company name or Apartment name',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Building or Company name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Suite / floor / door no.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _suiteFloorController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Suite 200 or Flat 501',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: AppButton(
                label: 'Save and continue',
                loading: _saving,
                onPressed: _saveAddressDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
