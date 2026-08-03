class PriorityContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  const PriorityContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory PriorityContact.fromJson(Map<String, dynamic> json) {
    return PriorityContact(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'איש קשר',
    );
  }
}

class SupportHotline {
  final String name;
  final String phone;
  final String note;

  const SupportHotline({
    required this.name,
    required this.phone,
    required this.note,
  });
}

const kIsraelSupportHotlines = <SupportHotline>[
  SupportHotline(
    name: 'נט״ל',
    phone: '1800363363',
    note: 'טראומה לאומית / פוסט־טראומה',
  ),
  SupportHotline(
    name: 'ער״ן',
    phone: '1201',
    note: 'תמיכה נפשית 24/7',
  ),
  SupportHotline(
    name: 'משטרה / חירום',
    phone: '100',
    note: 'מצב חירום מיידי',
  ),
];
