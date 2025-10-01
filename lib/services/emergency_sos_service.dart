import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../models/emergency_contact.dart';
import '../models/emergency_location_data.dart';
import 'emergency_permission_service.dart';

class EmergencySOSService {
  static const MethodChannel _smsChannel = MethodChannel('drivesync/sms');
  static const MethodChannel _callChannel = MethodChannel('drivesync/call');
  static final EmergencyPermissionService _permissionService = EmergencyPermissionService();
  
  // Singleton pattern
  static final EmergencySOSService _instance = EmergencySOSService._internal();
  factory EmergencySOSService() => _instance;
  EmergencySOSService._internal();

  static const String _contactsKey = 'emergency_contacts';
  static const String _sosEnabledKey = 'sos_enabled';
  static const String _autoTriggerKey = 'sos_auto_trigger';

  // SOS Settings
  bool _sosEnabled = false;
  bool _autoTriggerEnabled = true;
  List<EmergencyContact> _emergencyContacts = [];

  // Getters
  bool get sosEnabled => _sosEnabled;
  bool get autoTriggerEnabled => _autoTriggerEnabled;
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);

  // Initialize service and load settings
  Future<void> initialize() async {
    await _loadSettings();
    await _loadContacts();
    await _addTestContactIfEmpty();
    final permissionsReady = await _permissionService.ensureCriticalPermissions();
    if (!permissionsReady) {
      print('[WARN] Critical SOS permissions not fully granted during initialization.');
    }
  }

  // Add test contact for development/testing if no contacts exist
  Future<void> _addTestContactIfEmpty() async {
    if (_emergencyContacts.isEmpty) {
      final testContact = EmergencyContact(
        id: const Uuid().v4(),
        name: 'Test Emergency Contact',
        phoneNumber: '9325709787',
        type: ContactType.family,
        priority: 1,
      );
      await addEmergencyContact(testContact);
      print('🧪 TEST MODE: Added test emergency contact 9325709787');

      // Ensure SOS is enabled for immediate testing convenience
      await setSosEnabled(true);
      await setAutoTriggerEnabled(true);
      print('🧪 TEST MODE: Auto-enabled SOS & auto-trigger settings');
    }
  }

  // Load SOS settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sosEnabled = prefs.getBool(_sosEnabledKey) ?? false;
    _autoTriggerEnabled = prefs.getBool(_autoTriggerKey) ?? true;
  }

  // Save SOS settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sosEnabledKey, _sosEnabled);
    await prefs.setBool(_autoTriggerKey, _autoTriggerEnabled);
  }

  // Load emergency contacts from SharedPreferences
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString(_contactsKey);
    if (contactsJson != null) {
      final List<dynamic> contactsList = json.decode(contactsJson);
      _emergencyContacts = contactsList
          .map((contact) => EmergencyContact.fromJson(contact))
          .toList();
    }
  }

  // Save emergency contacts to SharedPreferences
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = json.encode(
      _emergencyContacts.map((contact) => contact.toJson()).toList(),
    );
    await prefs.setString(_contactsKey, contactsJson);
  }

  // Enable/Disable SOS
  Future<void> setSosEnabled(bool enabled) async {
    _sosEnabled = enabled;
    await _saveSettings();
  }

  // Enable/Disable Auto Trigger
  Future<void> setAutoTriggerEnabled(bool enabled) async {
    _autoTriggerEnabled = enabled;
    await _saveSettings();
  }

  // Add emergency contact
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _emergencyContacts.add(contact);
    await _saveContacts();
  }

  // Update emergency contact
  Future<void> updateEmergencyContact(String id, EmergencyContact updatedContact) async {
    final index = _emergencyContacts.indexWhere((contact) => contact.id == id);
    if (index != -1) {
      _emergencyContacts[index] = updatedContact;
      await _saveContacts();
    }
  }

  // Remove emergency contact
  Future<void> removeEmergencyContact(String id) async {
    _emergencyContacts.removeWhere((contact) => contact.id == id);
    await _saveContacts();
  }

  // Send emergency SMS using platform channel (Android only)
  Future<bool> sendEmergencySMS({
    required EmergencyContact contact,
    required EmergencyLocationData location,
    String? customMessage,
  }) async {
    final hasSmsPermission = await _permissionService.ensureSmsPermission();
    if (!hasSmsPermission) {
      print('[WARN] SMS permission missing for ${contact.phoneNumber}; aborting SMS send.');
      return false;
    }

    // Defensive validation: ensure coordinates are valid before sending
    if (!location.isValid) {
      print('[WARN] Invalid coordinates for ${contact.phoneNumber}; aborting SMS.');
      return false;
    }

    final message = customMessage ??
        'EMERGENCY! I need help at: ${location.formattedAddress}. My current location: ${location.googleMapsUrl} - Sent by DriveSync Safety App';

    final normalizedNumber = _normalizeNumber(contact.phoneNumber);
    print('[DEBUG] Sending emergency SMS to ${contact.phoneNumber} (normalized: $normalizedNumber)');
    print('[DEBUG] Location: ${location.latitude}, ${location.longitude}');
    print('[DEBUG] Message: $message');
    
    try {
      final bool? result = await _smsChannel.invokeMethod('sendSms', {
        'number': normalizedNumber,
        'message': message,
      });
      final ok = result == true;
      if (!ok) {
        // Fallback: open SMS composer so user can send manually
        final smsUri = 'sms:$normalizedNumber?body=${Uri.encodeComponent(message)}';
        try {
          await launchUrlString(smsUri);
        } catch (_) {
          // ignore - best-effort fallback
        }
      }
      return ok;
    } catch (e) {
      print('Failed to send SMS to ${contact.name}: $e');
      // Fallback to SMS app
      try {
        final smsUri = 'sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}';
        await launchUrlString(smsUri);
        return true;
      } catch (e2) {
        print('Failed to open SMS app: $e2');
        return false;
      }
    }
  }

  // Normalize numbers: if 10-digit local number, prefix +91
  String _normalizeNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.startsWith('0') && digits.length == 11) return '+91${digits.substring(1)}';
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    if (raw.startsWith('+')) return raw;
    return raw; // fallback
  }

  // Make an emergency call automatically using platform channel (Android only)
  Future<bool> makeEmergencyCall(EmergencyContact contact) async {
    final hasPhonePermission = await _permissionService.ensurePhonePermission();
    if (!hasPhonePermission) {
      print('[WARN] Phone permission missing for ${contact.phoneNumber}; aborting emergency call.');
      return false;
    }

    try {
      final bool? result = await _callChannel.invokeMethod('makeCall', {
        'number': contact.phoneNumber,
      });
      if (result == true) {
        return true;
      } else {
        // Fallback to phone app
        final phoneUri = 'tel:${contact.phoneNumber}';
        await launchUrlString(phoneUri);
        return true;
      }
    } catch (e) {
      print('Failed to make call to ${contact.name}: $e');
      // Fallback to phone app
      try {
        final phoneUri = 'tel:${contact.phoneNumber}';
        await launchUrlString(phoneUri);
        return true;
      } catch (e2) {
        print('Failed to open phone app: $e2');
        return false;
      }
    }
  }

  // Trigger emergency SOS
  Future<bool> triggerEmergencySOS({
    required EmergencyLocationData userLocation,
    String? customMessage,
  }) async {
    final hasAllPermissions = await _permissionService.ensureCriticalPermissions();
    if (!hasAllPermissions) {
      print('[WARN] Missing critical permissions; attempting best-effort SOS.');
    }

    if (!_sosEnabled || _emergencyContacts.isEmpty) {
      print('[WARN] SOS not enabled or no emergency contacts configured');
      return false;
    }

    print('[INFO] Triggering emergency SOS for ${_emergencyContacts.length} contacts');
    
    bool success = true;
    
    // Sort contacts by priority (lower number = higher priority)
    final sortedContacts = List<EmergencyContact>.from(_emergencyContacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final contact in sortedContacts) {
      try {
        // Send SMS to all contacts
        final smsResult = await sendEmergencySMS(
          contact: contact,
          location: userLocation,
          customMessage: customMessage,
        );
        
        if (!smsResult) {
          success = false;
        }

        // For police and family, also make a call
        if (contact.type == ContactType.police || 
            contact.type == ContactType.family) {
          final callResult = await makeEmergencyCall(contact);
          if (!callResult) {
            success = false;
          }
          
          // Add a small delay between calls
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        print('Error processing emergency contact ${contact.name}: $e');
        success = false;
        // Continue with next contact even if one fails
        continue;
      }
    }

    return success;
  }

  // Check if SOS can be triggered (has contacts and is enabled)
  bool canTriggerSOS() {
    return _sosEnabled && _emergencyContacts.isNotEmpty;
  }

  // Get emergency contacts by type
  List<EmergencyContact> getContactsByType(ContactType type) {
    return _emergencyContacts.where((contact) => contact.type == type).toList();
  }

  // Get contact count by type
  Map<ContactType, int> getContactCounts() {
    final counts = <ContactType, int>{};
    for (final type in ContactType.values) {
      counts[type] = getContactsByType(type).length;
    }
    return counts;
  }
}