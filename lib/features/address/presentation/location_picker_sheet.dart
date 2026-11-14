import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:handyman_mart/core/theme/app_theme.dart';
import 'package:handyman_mart/core/widgets/app_button.dart';

/// Modal bottom sheet or screen for picking / confirming delivery location pin on interactive map.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.addressText,
  });

  final double initialLat;
  final double initialLng;
  final String addressText;

  static Future<ll.LatLng?> show(
    BuildContext context, {
    double initialLat = 17.6868,
    double initialLng = 83.2185,
    String addressText = 'Visakhapatnam',
  }) {
    return showModalBottomSheet<ll.LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(
        initialLat: initialLat == 0 ? 17.6868 : initialLat,
        initialLng: initialLng == 0 ? 83.2185 : initialLng,
        addressText: addressText,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late ll.LatLng _selectedPin;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPin = ll.LatLng(widget.initialLat, widget.initialLng);
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
                const Icon(Icons.pin_drop_rounded, color: AppColors.amberDeep, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Set Delivery Location Pin',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPin,
                    initialZoom: 15.5,
                    onTap: (_, point) {
                      setState(() => _selectedPin = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.handyman.mart',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPin,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                    onPressed: () {
                      _mapController.move(_selectedPin, 16.0);
                    },
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city_rounded, size: 18, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.addressText.isEmpty ? 'Selected Location Coordinates' : widget.addressText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pin: ${_selectedPin.latitude.toStringAsFixed(5)}, ${_selectedPin.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Confirm Location Pin',
                  onPressed: () => Navigator.pop(context, _selectedPin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
