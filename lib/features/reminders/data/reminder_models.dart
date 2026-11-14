/// Auto-order and scheduled replenishment reminder model.
class AutoOrderReminder {
  const AutoOrderReminder({
    required this.id,
    required this.title,
    required this.itemNames,
    required this.frequency,
    required this.nextDueDate,
    required this.isEnabled,
    required this.offerTitle,
    required this.discountAmount,
  });

  final String id;
  final String title;
  final List<String> itemNames;

  /// 'Daily', 'Weekly', 'Monthly', 'Every 15 Days'
  final String frequency;
  final DateTime nextDueDate;
  final bool isEnabled;
  final String offerTitle;
  final int discountAmount;

  AutoOrderReminder copyWith({
    String? id,
    String? title,
    List<String>? itemNames,
    String? frequency,
    DateTime? nextDueDate,
    bool? isEnabled,
    String? offerTitle,
    int? discountAmount,
  }) {
    return AutoOrderReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      itemNames: itemNames ?? this.itemNames,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isEnabled: isEnabled ?? this.isEnabled,
      offerTitle: offerTitle ?? this.offerTitle,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'itemNames': itemNames,
        'frequency': frequency,
        'nextDueDate': nextDueDate.toIso8601String(),
        'isEnabled': isEnabled,
        'offerTitle': offerTitle,
        'discountAmount': discountAmount,
      };

  factory AutoOrderReminder.fromJson(Map<String, dynamic> json) {
    return AutoOrderReminder(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      itemNames: json['itemNames'] is List
          ? [for (final i in json['itemNames'] as List) i.toString()]
          : const [],
      frequency: (json['frequency'] ?? 'Weekly').toString(),
      nextDueDate: DateTime.tryParse((json['nextDueDate'] ?? '').toString()) ??
          DateTime.now().add(const Duration(days: 7)),
      isEnabled: json['isEnabled'] == true,
      offerTitle: (json['offerTitle'] ?? '').toString(),
      discountAmount: int.tryParse((json['discountAmount'] ?? '0').toString()) ?? 0,
    );
  }
}

/// Active Customer Offer / Cashback Milestone.
class CustomerOfferMilestone {
  const CustomerOfferMilestone({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.isClaimed,
    required this.benefitAmount,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final bool isClaimed;
  final int benefitAmount;
}
