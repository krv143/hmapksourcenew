/// Returns dynamic delivery time estimate based on customer pincode.
String estimatePincodeDeliveryEta(String pincode) {
  final pin = pincode.trim();
  if (pin.isEmpty) return '⚡ 20–30 mins';

  final numPin = int.tryParse(pin) ?? 0;

  // Visakhapatnam Urban Core (530001 - 530025)
  if (numPin >= 530001 && numPin <= 530025) {
    return '⚡ 15–25 mins';
  }

  // Visakhapatnam Outer / Suburban (530026 - 530055, 531162, 531163...)
  if ((numPin >= 530026 && numPin <= 530055) || pin.startsWith('531')) {
    return '⚡ 25–35 mins';
  }

  // AP District Capitals & Telangana Urban (Srikakulam 532..., Vizianagaram 535..., Guntur 522..., Tirupati 517..., Hyderabad 500...)
  if (pin.startsWith('532') ||
      pin.startsWith('535') ||
      pin.startsWith('533') ||
      pin.startsWith('534') ||
      pin.startsWith('522') ||
      pin.startsWith('517') ||
      pin.startsWith('500') ||
      pin.startsWith('506')) {
    return '⏱️ 35–45 mins';
  }

  return '🚚 45–60 mins';
}
