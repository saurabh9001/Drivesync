class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final ContactType type;
  final int priority; // Lower number means higher priority

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.type,
    required this.priority,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      type: ContactType.values.firstWhere(
        (e) => e.toString() == 'ContactType.${json['type']}',
        orElse: () => ContactType.family,
      ),
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'type': type.toString().split('.').last,
      'priority': priority,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    ContactType? type,
    int? priority,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      type: type ?? this.type,
      priority: priority ?? this.priority,
    );
  }
}

enum ContactType {
  hospital,
  police,
  family,
}

extension ContactTypeExtension on ContactType {
  String get displayName {
    switch (this) {
      case ContactType.hospital:
        return 'Hospital/Ambulance';
      case ContactType.police:
        return 'Police';
      case ContactType.family:
        return 'Family/Friend';
    }
  }

  String get icon {
    switch (this) {
      case ContactType.hospital:
        return '🏥';
      case ContactType.police:
        return '👮';
      case ContactType.family:
        return '👨‍👩‍👧‍👦';
    }
  }
}