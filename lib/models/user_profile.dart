class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String emergencyContactName;
  final String driverExperience;
  final String vehicleType;
  final bool enableSoundAlerts;
  final bool enableVibrationAlerts;
  final double alertSensitivity;
  final String routePreference;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.emergencyContact,
    required this.emergencyContactName,
    required this.driverExperience,
    required this.vehicleType,
    this.enableSoundAlerts = true,
    this.enableVibrationAlerts = true,
    this.alertSensitivity = 7.0,
    this.routePreference = 'balanced',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      driverExperience: json['driverExperience'] ?? 'intermediate',
      vehicleType: json['vehicleType'] ?? 'car',
      enableSoundAlerts: json['enableSoundAlerts'] ?? true,
      enableVibrationAlerts: json['enableVibrationAlerts'] ?? true,
      alertSensitivity: (json['alertSensitivity'] ?? 7.0).toDouble(),
      routePreference: json['routePreference'] ?? 'balanced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'driverExperience': driverExperience,
      'vehicleType': vehicleType,
      'enableSoundAlerts': enableSoundAlerts,
      'enableVibrationAlerts': enableVibrationAlerts,
      'alertSensitivity': alertSensitivity,
      'routePreference': routePreference,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? emergencyContact,
    String? emergencyContactName,
    String? driverExperience,
    String? vehicleType,
    bool? enableSoundAlerts,
    bool? enableVibrationAlerts,
    double? alertSensitivity,
    String? routePreference,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      driverExperience: driverExperience ?? this.driverExperience,
      vehicleType: vehicleType ?? this.vehicleType,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      enableVibrationAlerts: enableVibrationAlerts ?? this.enableVibrationAlerts,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
      routePreference: routePreference ?? this.routePreference,
    );
  }
}